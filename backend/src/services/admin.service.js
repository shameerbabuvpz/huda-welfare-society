const bcrypt = require('bcryptjs');
const db = require('../config/database');
const ApiError = require('../utils/ApiError');
const { paginate, paginationMeta } = require('../utils/pagination');
const auditService = require('./audit.service');

const adminService = {
  async list(orgId, { page = 1, search } = {}) {
    let query = db('users')
      .where({ organization_id: orgId })
      .whereIn('role', ['admin', 'super_admin'])
      .select('id', 'name', 'phone', 'email', 'role', 'status', 'created_at', 'updated_at');

    if (search) {
      query = query.where(function () {
        this.where('name', 'ilike', `%${search}%`)
          .orWhere('phone', 'ilike', `%${search}%`)
          .orWhere('email', 'ilike', `%${search}%`);
      });
    }

    const countQuery = query.clone().clearSelect().clearOrder().count('id as count').first();
    const { query: paginated, page: p, limit } = paginate(query.orderBy('created_at', 'desc'), { page });

    const [data, total] = await Promise.all([paginated, countQuery]);
    return { data, pagination: paginationMeta(parseInt(total.count, 10), p, limit) };
  },

  async getById(orgId, adminId) {
    const admin = await db('users')
      .where({ id: adminId, organization_id: orgId })
      .whereIn('role', ['admin', 'super_admin'])
      .select('id', 'name', 'phone', 'email', 'role', 'status', 'created_at', 'updated_at')
      .first();
    if (!admin) throw ApiError.notFound('Admin not found');
    return admin;
  },

  async create(orgId, data, actorId) {
    // Validate phone uniqueness
    if (data.phone) {
      const existingPhone = await db('users').where({ phone: data.phone }).first();
      if (existingPhone) throw ApiError.conflict('Phone number already in use');
    }

    // Validate email uniqueness
    if (data.email) {
      const existingEmail = await db('users').where({ email: data.email }).first();
      if (existingEmail) throw ApiError.conflict('Email already in use');
    }

    if (!data.phone) {
      throw ApiError.badRequest('Phone number is required');
    }

    const insertData = {
      organization_id: orgId,
      name: data.name || null,
      phone: data.phone,
      email: data.email || null,
      password_hash: data.password ? await bcrypt.hash(data.password, 12) : null,
      role: 'admin',
      status: 'active',
    };

    const [admin] = await db('users').insert(insertData).returning('*');

    await auditService.log({
      organizationId: orgId,
      actorId,
      action: 'admin.create',
      entityType: 'user',
      entityId: admin.id,
      details: { name: admin.name, phone: admin.phone },
    });

    return {
      id: admin.id,
      name: admin.name,
      phone: admin.phone,
      email: admin.email,
      role: admin.role,
      status: admin.status,
      created_at: admin.created_at,
    };
  },

  async update(orgId, adminId, data, actorId) {
    const existing = await db('users')
      .where({ id: adminId, organization_id: orgId })
      .whereIn('role', ['admin', 'super_admin'])
      .first();
    if (!existing) throw ApiError.notFound('Admin not found');

    // Don't allow editing self to prevent lockout
    if (adminId === actorId && data.status === 'inactive') {
      throw ApiError.badRequest('Cannot deactivate your own account');
    }

    const allowed = {};
    if (data.name !== undefined) allowed.name = data.name;
    if (data.email !== undefined) {
      if (data.email) {
        const dup = await db('users').where({ email: data.email }).whereNot({ id: adminId }).first();
        if (dup) throw ApiError.conflict('Email already in use');
      }
      allowed.email = data.email;
    }
    if (data.phone !== undefined) {
      if (data.phone) {
        const dup = await db('users').where({ phone: data.phone }).whereNot({ id: adminId }).first();
        if (dup) throw ApiError.conflict('Phone number already in use');
      }
      allowed.phone = data.phone;
    }
    if (data.status !== undefined) allowed.status = data.status;

    const [updated] = await db('users')
      .where({ id: adminId })
      .update({ ...allowed, updated_at: db.fn.now() })
      .returning('*');

    await auditService.log({
      organizationId: orgId,
      actorId,
      action: 'admin.update',
      entityType: 'user',
      entityId: adminId,
      details: allowed,
    });

    return {
      id: updated.id,
      name: updated.name,
      phone: updated.phone,
      email: updated.email,
      role: updated.role,
      status: updated.status,
      created_at: updated.created_at,
      updated_at: updated.updated_at,
    };
  },

  async remove(orgId, adminId, actorId) {
    if (adminId === actorId) {
      throw ApiError.badRequest('Cannot delete your own account');
    }

    const existing = await db('users')
      .where({ id: adminId, organization_id: orgId })
      .whereIn('role', ['admin', 'super_admin'])
      .first();
    if (!existing) throw ApiError.notFound('Admin not found');

    // Soft delete by setting status to inactive
    await db('users')
      .where({ id: adminId })
      .update({ status: 'inactive', updated_at: db.fn.now() });

    await auditService.log({
      organizationId: orgId,
      actorId,
      action: 'admin.delete',
      entityType: 'user',
      entityId: adminId,
      details: { name: existing.name },
    });
  },
};

module.exports = adminService;
