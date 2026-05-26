const db = require('../config/database');
const ApiError = require('../utils/ApiError');
const { generateKuriCode } = require('../utils/generateCode');
const { paginationMeta } = require('../utils/pagination');
const auditService = require('./audit.service');

const kuriService = {
  // ── Group management ──
  async createGroup(orgId, data, actorId) {
    const code = data.code || generateKuriCode();
    const [group] = await db('kuri_groups').insert({
      organization_id: orgId,
      name: data.name,
      code,
      total_members: data.total_members,
      monthly_amount: data.monthly_amount,
      duration_months: data.duration_months,
      start_date: data.start_date,
      status: 'active',
      created_by: actorId,
      updated_by: actorId,
    }).returning('*');

    await auditService.log({
      organizationId: orgId, actorId, action: 'kuri_group.create',
      entityType: 'kuri_group', entityId: group.id, details: { name: data.name },
    });
    return group;
  },

  async listGroups(orgId, { page = 1, limit = 20, status, search }) {
    let query = db('kuri_groups').where({ organization_id: orgId });
    if (status) query = query.andWhere({ status });
    if (search) {
      query = query.andWhere(function () {
        this.where('name', 'ilike', `%${search}%`).orWhere('code', 'ilike', `%${search}%`);
      });
    }
    const total = await query.clone().count('id as count').first();
    const p = Math.max(1, parseInt(page, 10));
    const l = Math.min(100, Math.max(1, parseInt(limit, 10)));
    const rows = await query.orderBy('id', 'desc').limit(l).offset((p - 1) * l);
    return { data: rows, pagination: paginationMeta(parseInt(total.count, 10), p, l) };
  },

  async getGroup(orgId, groupId) {
    const group = await db('kuri_groups').where({ id: groupId, organization_id: orgId }).first();
    if (!group) throw ApiError.notFound('Kuri group not found');

    let members;
    try {
      members = await db('kuri_members')
        .where({ 'kuri_members.kuri_group_id': groupId, 'kuri_members.organization_id': orgId })
        .join('members', 'kuri_members.member_id', 'members.id')
        .leftJoin('ayalkoottams', 'members.ayalkoottam_id', 'ayalkoottams.id')
        .select(
          'kuri_members.*',
          'members.name as member_name',
          'members.member_code',
          'members.phone as member_phone',
          'members.is_guest',
          'ayalkoottams.name as ayalkoottam_name',
        );
    } catch (e) {
      // Fallback if is_guest column doesn't exist yet
      members = await db('kuri_members')
        .where({ 'kuri_members.kuri_group_id': groupId, 'kuri_members.organization_id': orgId })
        .join('members', 'kuri_members.member_id', 'members.id')
        .leftJoin('ayalkoottams', 'members.ayalkoottam_id', 'ayalkoottams.id')
        .select(
          'kuri_members.*',
          'members.name as member_name',
          'members.member_code',
          'members.phone as member_phone',
          'ayalkoottams.name as ayalkoottam_name',
        );
    }

    const winners = await db('kuri_winners')
      .where({ 'kuri_winners.kuri_group_id': groupId, 'kuri_winners.organization_id': orgId })
      .join('members', 'kuri_winners.member_id', 'members.id')
      .select('kuri_winners.*', 'members.name as member_name')
      .orderBy('month_number');

    return { ...group, members, winners };
  },

  async updateGroup(orgId, groupId, data, actorId) {
    const [group] = await db('kuri_groups')
      .where({ id: groupId, organization_id: orgId })
      .update({ ...data, updated_by: actorId, updated_at: db.fn.now() })
      .returning('*');
    if (!group) throw ApiError.notFound('Kuri group not found');
    return group;
  },

  // ── Member enrollment ──
  async addMember(orgId, groupId, memberId, actorId) {
    const group = await db('kuri_groups').where({ id: groupId, organization_id: orgId }).first();
    if (!group) throw ApiError.notFound('Kuri group not found');

    const member = await db('members').where({ id: memberId, organization_id: orgId }).first();
    if (!member) throw ApiError.notFound('Member not found');

    const currentCount = await db('kuri_members').where({ kuri_group_id: groupId }).count('id as count').first();
    if (parseInt(currentCount.count, 10) >= group.total_members) {
      throw ApiError.conflict('Kuri group is full');
    }

    const existing = await db('kuri_members').where({ kuri_group_id: groupId, member_id: memberId }).first();
    if (existing) throw ApiError.conflict('Member already enrolled in this group');

    const slotNumber = parseInt(currentCount.count, 10) + 1;
    const [km] = await db('kuri_members').insert({
      organization_id: orgId,
      kuri_group_id: groupId,
      member_id: memberId,
      slot_number: slotNumber,
      status: 'active',
    }).returning('*');

    return km;
  },

  async addGuestMember(orgId, groupId, { name, phone }, actorId) {
    const group = await db('kuri_groups').where({ id: groupId, organization_id: orgId }).first();
    if (!group) throw ApiError.notFound('Kuri group not found');

    const currentCount = await db('kuri_members').where({ kuri_group_id: groupId }).count('id as count').first();
    if (parseInt(currentCount.count, 10) >= group.total_members) {
      throw ApiError.conflict('Kuri group is full');
    }

    // Create a guest member record
    const guestCode = `GUEST-${Date.now().toString(36).toUpperCase()}`;
    let member;
    try {
      [member] = await db('members').insert({
        organization_id: orgId,
        member_code: guestCode,
        name,
        phone: phone || null,
        status: 'active',
        is_guest: true,
        created_by: actorId,
        updated_by: actorId,
      }).returning('*');
    } catch (e) {
      // Fallback if is_guest column doesn't exist yet
      [member] = await db('members').insert({
        organization_id: orgId,
        member_code: guestCode,
        name,
        phone: phone || null,
        status: 'active',
        created_by: actorId,
        updated_by: actorId,
      }).returning('*');
    }

    const slotNumber = parseInt(currentCount.count, 10) + 1;
    const [km] = await db('kuri_members').insert({
      organization_id: orgId,
      kuri_group_id: groupId,
      member_id: member.id,
      slot_number: slotNumber,
      status: 'active',
    }).returning('*');

    return { ...km, member_name: name, member_phone: phone, is_guest: true };
  },

  async removeGroupMember(orgId, groupId, memberId) {
    const [km] = await db('kuri_members')
      .where({ kuri_group_id: groupId, member_id: memberId, organization_id: orgId })
      .update({ status: 'withdrawn', updated_at: db.fn.now() })
      .returning('*');
    if (!km) throw ApiError.notFound('Member not found in this group');
    return km;
  },

  // ── Collections ──
  async recordCollection(orgId, groupId, { memberId, monthNumber, amount, paidDate }, actorId) {
    const group = await db('kuri_groups').where({ id: groupId, organization_id: orgId }).first();
    if (!group) throw ApiError.notFound('Kuri group not found');

    if (monthNumber > group.duration_months) {
      throw ApiError.badRequest('Month number exceeds group duration');
    }

    // Check if already paid
    const existing = await db('kuri_collections')
      .where({ kuri_group_id: groupId, member_id: memberId, month_number: monthNumber, status: 'paid' })
      .first();
    if (existing) throw ApiError.conflict('Payment already recorded for this month');

    const [collection] = await db('kuri_collections').insert({
      organization_id: orgId,
      kuri_group_id: groupId,
      member_id: memberId,
      month_number: monthNumber,
      amount: amount || group.monthly_amount,
      paid_date: paidDate || new Date(),
      status: 'paid',
      created_by: actorId,
    }).returning('*');

    return collection;
  },

  async getCollections(orgId, groupId, { monthNumber, memberId } = {}) {
    let query = db('kuri_collections')
      .where({ 'kuri_collections.organization_id': orgId, 'kuri_collections.kuri_group_id': groupId })
      .join('members', 'kuri_collections.member_id', 'members.id')
      .select('kuri_collections.*', 'members.name as member_name');

    if (monthNumber) query = query.andWhere({ 'kuri_collections.month_number': monthNumber });
    if (memberId) query = query.andWhere({ 'kuri_collections.member_id': memberId });

    return query.orderBy('kuri_collections.month_number').orderBy('members.name');
  },

  // ── Winner selection ──
  async selectWinner(orgId, groupId, { memberId, monthNumber }, actorId) {
    const group = await db('kuri_groups').where({ id: groupId, organization_id: orgId }).first();
    if (!group) throw ApiError.notFound('Kuri group not found');

    if (monthNumber > group.duration_months) {
      throw ApiError.badRequest('Month number exceeds group duration');
    }

    // Check if month already has winner
    const monthWinner = await db('kuri_winners')
      .where({ kuri_group_id: groupId, month_number: monthNumber })
      .first();
    if (monthWinner) throw ApiError.conflict('Winner already selected for this month');

    // Check if member already won in this group
    const memberWon = await db('kuri_winners')
      .where({ kuri_group_id: groupId, member_id: memberId })
      .first();
    if (memberWon) throw ApiError.conflict('Member already won in this kuri group');

    // Verify member is enrolled
    const enrolled = await db('kuri_members')
      .where({ kuri_group_id: groupId, member_id: memberId, status: 'active' })
      .first();
    if (!enrolled) throw ApiError.badRequest('Member is not enrolled in this group');

    const [winner] = await db('kuri_winners').insert({
      organization_id: orgId,
      kuri_group_id: groupId,
      member_id: memberId,
      month_number: monthNumber,
      won_date: new Date(),
    }).returning('*');

    await auditService.log({
      organizationId: orgId, actorId, action: 'kuri.winner_selected',
      entityType: 'kuri_winner', entityId: winner.id,
      details: { groupId, memberId, monthNumber },
    });

    return winner;
  },

  // ── Payouts ──
  async recordPayout(orgId, groupId, { winnerId, amount, payoutDate, reference }, actorId) {
    const winner = await db('kuri_winners')
      .where({ id: winnerId, kuri_group_id: groupId, organization_id: orgId })
      .first();
    if (!winner) throw ApiError.notFound('Winner record not found');

    // Check if payout already exists
    const existing = await db('kuri_payouts').where({ kuri_winner_id: winnerId }).first();
    if (existing) throw ApiError.conflict('Payout already recorded for this winner');

    const [payout] = await db('kuri_payouts').insert({
      organization_id: orgId,
      kuri_group_id: groupId,
      member_id: winner.member_id,
      kuri_winner_id: winnerId,
      amount,
      payout_date: payoutDate || new Date(),
      reference,
      created_by: actorId,
    }).returning('*');

    await auditService.log({
      organizationId: orgId, actorId, action: 'kuri.payout',
      entityType: 'kuri_payout', entityId: payout.id,
      details: { groupId, amount },
    });

    return payout;
  },

  // ── Member views ──
  async memberPaymentStatus(orgId, memberId) {
    const groups = await db('kuri_members')
      .where({ 'kuri_members.organization_id': orgId, 'kuri_members.member_id': memberId, 'kuri_members.status': 'active' })
      .join('kuri_groups', 'kuri_members.kuri_group_id', 'kuri_groups.id')
      .select('kuri_groups.*', 'kuri_members.slot_number');

    const result = [];
    for (const group of groups) {
      const collections = await db('kuri_collections')
        .where({ kuri_group_id: group.id, member_id: memberId });
      const paidMonths = collections.filter(c => c.status === 'paid').map(c => c.month_number);
      const pendingMonths = [];
      for (let m = 1; m <= group.duration_months; m++) {
        if (!paidMonths.includes(m)) pendingMonths.push(m);
      }

      const winRecord = await db('kuri_winners')
        .where({ kuri_group_id: group.id, member_id: memberId })
        .first();

      result.push({
        group: { id: group.id, name: group.name, code: group.code, monthly_amount: group.monthly_amount },
        slot_number: group.slot_number,
        paid_months: paidMonths,
        pending_months: pendingMonths,
        has_won: !!winRecord,
        win_month: winRecord ? winRecord.month_number : null,
      });
    }

    return result;
  },

  async winnerHistory(orgId, groupId) {
    return db('kuri_winners')
      .where({ 'kuri_winners.organization_id': orgId, 'kuri_winners.kuri_group_id': groupId })
      .join('members', 'kuri_winners.member_id', 'members.id')
      .leftJoin('kuri_payouts', 'kuri_winners.id', 'kuri_payouts.kuri_winner_id')
      .select(
        'kuri_winners.*',
        'members.name as member_name',
        'kuri_payouts.amount as payout_amount',
        'kuri_payouts.payout_date'
      )
      .orderBy('kuri_winners.month_number');
  },
};

module.exports = kuriService;
