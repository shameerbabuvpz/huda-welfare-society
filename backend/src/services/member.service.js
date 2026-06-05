const bcrypt = require('bcryptjs');
const db = require('../config/database');
const ApiError = require('../utils/ApiError');
const { generateMemberCode } = require('../utils/generateCode');
const { paginationMeta } = require('../utils/pagination');
const auditService = require('./audit.service');

const memberService = {
  async create(orgId, data, actorId) {
    const memberCode = data.member_code || generateMemberCode();

    // Create user account for member with phone (required for OTP login)
    let userId = null;
    if (data.phone) {
      const existingUser = await db('users').where({ phone: data.phone }).first();
      if (existingUser) {
        // If user already exists with this phone, link to it
        userId = existingUser.id;
      } else {
        const [user] = await db('users').insert({
          phone: data.phone,
          name: data.name,
          email: data.email || null,
          role: 'member',
          organization_id: orgId,
          status: 'active',
        }).returning('*');
        userId = user.id;
      }
    } else if (data.email) {
      const existingUser = await db('users').where({ email: data.email }).first();
      if (existingUser) throw ApiError.conflict('Email already in use');

      const defaultPassword = 'member123';
      const password_hash = await bcrypt.hash(defaultPassword, 12);
      const [user] = await db('users').insert({
        email: data.email,
        password_hash,
        role: 'member',
        organization_id: orgId,
        status: 'active',
      }).returning('*');
      userId = user.id;
    }

    // Handle designation (president/secretary) - only one per ayalkoottam
    const designation = data.designation || null;
    if (designation && data.ayalkoottam_id) {
      const existing = await db('members')
        .where({ ayalkoottam_id: data.ayalkoottam_id, designation, status: 'active' })
        .first();
      if (existing) {
        // Remove designation from existing member
        await db('members').where({ id: existing.id }).update({ designation: null, updated_at: db.fn.now() });
      }
    }

    const [member] = await db('members').insert({
      organization_id: orgId,
      ayalkoottam_id: data.ayalkoottam_id || null,
      user_id: userId,
      member_code: memberCode,
      name: data.name,
      phone: data.phone,
      email: data.email,
      address: data.address,
      designation,
      join_date: data.join_date || new Date(),
      status: 'active',
      created_by: actorId,
      updated_by: actorId,
    }).returning('*');

    await auditService.log({
      organizationId: orgId,
      actorId,
      action: 'member.create',
      entityType: 'member',
      entityId: member.id,
      details: { name: data.name },
    });

    return member;
  },

  async list(orgId, { page = 1, limit = 20, status, search, ayalkoottam_id }) {
    let query = db('members')
      .where({ 'members.organization_id': orgId })
      .leftJoin('ayalkoottams', 'members.ayalkoottam_id', 'ayalkoottams.id')
      .select('members.*', 'ayalkoottams.name as ayalkoottam_name');
    if (status) query = query.andWhere({ 'members.status': status });
    if (ayalkoottam_id) query = query.andWhere({ 'members.ayalkoottam_id': ayalkoottam_id });
    if (search) {
      query = query.andWhere(function () {
        this.where('members.name', 'ilike', `%${search}%`)
          .orWhere('members.member_code', 'ilike', `%${search}%`)
          .orWhere('members.phone', 'ilike', `%${search}%`);
      });
    }

    const total = await query.clone().clearSelect().count('members.id as count').first();
    const p = Math.max(1, parseInt(page, 10));
    const l = Math.min(100, Math.max(1, parseInt(limit, 10)));
    const rows = await query.orderBy('members.id', 'desc').limit(l).offset((p - 1) * l);

    return { data: rows, pagination: paginationMeta(parseInt(total.count, 10), p, l) };
  },

  async getById(orgId, memberId) {
    const member = await db('members').where({ id: memberId, organization_id: orgId }).first();
    if (!member) throw ApiError.notFound('Member not found');
    return member;
  },

  async update(orgId, memberId, data, actorId) {
    const existingMember = await db('members').where({ id: memberId, organization_id: orgId }).first();
    if (!existingMember) throw ApiError.notFound('Member not found');

    // An office bearer (president/secretary) must always belong to an
    // ayalkoottam, otherwise they silently vanish from the office-bearers
    // report. Block any update whose result would be a designated member with
    // no ayalkoottam.
    const resultingDesignation = 'designation' in data ? data.designation : existingMember.designation;
    const resultingAkId = 'ayalkoottam_id' in data ? data.ayalkoottam_id : existingMember.ayalkoottam_id;
    if (resultingDesignation && !resultingAkId) {
      throw ApiError.badRequest('Select an ayalkoottam before assigning a president or secretary');
    }

    // Handle designation (president/secretary) - only one per ayalkoottam.
    // If a designation is being assigned, clear it from any other active member
    // in the same ayalkoottam first.
    if (data.designation) {
      await db('members')
        .where({ ayalkoottam_id: resultingAkId, designation: data.designation, status: 'active' })
        .whereNot({ id: memberId })
        .update({ designation: null, updated_at: db.fn.now() });
    }

    const [member] = await db('members')
      .where({ id: memberId, organization_id: orgId })
      .update({ ...data, updated_by: actorId, updated_at: db.fn.now() })
      .returning('*');
    if (!member) throw ApiError.notFound('Member not found');

    // Sync phone/name to linked user account
    if (existingMember.user_id && (data.phone || data.name)) {
      const userUpdate = {};
      if (data.phone) userUpdate.phone = data.phone;
      if (data.name) userUpdate.name = data.name;
      await db('users').where({ id: existingMember.user_id }).update({ ...userUpdate, updated_at: db.fn.now() });
    }

    // Create user account if member didn't have one but now has a phone
    if (!existingMember.user_id && data.phone) {
      let user = await db('users').where({ phone: data.phone }).first();
      if (!user) {
        [user] = await db('users').insert({
          phone: data.phone,
          name: data.name || existingMember.name,
          role: 'member',
          organization_id: orgId,
          status: 'active',
        }).returning('*');
      }
      await db('members').where({ id: memberId }).update({ user_id: user.id });
      member.user_id = user.id;
    }

    await auditService.log({
      organizationId: orgId,
      actorId,
      action: 'member.update',
      entityType: 'member',
      entityId: memberId,
      details: data,
    });

    return member;
  },

  async softDelete(orgId, memberId, actorId) {
    const [member] = await db('members')
      .where({ id: memberId, organization_id: orgId })
      .update({ status: 'inactive', updated_by: actorId, updated_at: db.fn.now() })
      .returning('*');
    if (!member) throw ApiError.notFound('Member not found');

    // Deactivate linked user
    if (member.user_id) {
      await db('users').where({ id: member.user_id }).update({ status: 'inactive', updated_at: db.fn.now() });
    }

    await auditService.log({
      organizationId: orgId,
      actorId,
      action: 'member.delete',
      entityType: 'member',
      entityId: memberId,
    });

    return member;
  },

  async getProfile(orgId, userId) {
    // Try by user_id first
    let member = await db('members')
      .leftJoin('ayalkoottams', 'members.ayalkoottam_id', 'ayalkoottams.id')
      .where({ 'members.organization_id': orgId, 'members.user_id': userId })
      .select('members.*', 'ayalkoottams.name as ayalkoottam_name')
      .first();
    if (!member) {
      // Fall back: match by phone via users table
      const user = await db('users').where({ id: userId }).first();
      if (user && user.phone) {
        member = await db('members')
          .leftJoin('ayalkoottams', 'members.ayalkoottam_id', 'ayalkoottams.id')
          .where({ 'members.organization_id': orgId, 'members.phone': user.phone, 'members.status': 'active' })
          .select('members.*', 'ayalkoottams.name as ayalkoottam_name')
          .first();
        if (member && !member.user_id) {
          // Auto-link for future lookups
          await db('members').where({ id: member.id }).update({ user_id: userId, updated_at: db.fn.now() });
          member.user_id = userId;
        }
      }
    }
    if (!member) throw ApiError.notFound('Member profile not found');
    return member;
  },

  /**
   * List members of the requesting member's own ayalkoottam.
   * Only available to the president/secretary of that ayalkoottam.
   * Returns lightweight contact info (name, code, phone) for calling.
   */
  async listMyAyalkoottam(orgId, userId, { search } = {}) {
    const me = await this.getProfile(orgId, userId);

    if (!['president', 'secretary'].includes(me.designation)) {
      throw ApiError.forbidden('Only the president or secretary can view the member directory');
    }
    if (!me.ayalkoottam_id) {
      throw ApiError.badRequest('You are not assigned to an ayalkoottam');
    }

    let query = db('members')
      .where({
        organization_id: orgId,
        ayalkoottam_id: me.ayalkoottam_id,
        status: 'active',
      })
      .select('id', 'member_code', 'name', 'phone', 'photo_url', 'designation');

    if (search) {
      query = query.andWhere(function () {
        this.where('name', 'ilike', `%${search}%`)
          .orWhere('member_code', 'ilike', `%${search}%`)
          .orWhere('phone', 'ilike', `%${search}%`);
      });
    }

    const rows = await query.orderBy('name', 'asc');

    return {
      ayalkoottam: { id: me.ayalkoottam_id, name: me.ayalkoottam_name || null },
      data: rows,
    };
  },

  /**
   * Check if a designation (president/secretary) is already taken in an ayalkoottam
   */
  async checkDesignation(orgId, ayalkoottamId, designation) {
    const existing = await db('members')
      .where({ organization_id: orgId, ayalkoottam_id: ayalkoottamId, designation, status: 'active' })
      .first();
    return { exists: !!existing, member: existing ? { id: existing.id, name: existing.name } : null };
  },
};

module.exports = memberService;
