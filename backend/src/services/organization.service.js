const db = require('../config/database');
const ApiError = require('../utils/ApiError');
const { paginationMeta } = require('../utils/pagination');

const organizationService = {
  async create(data) {
    const [org] = await db('organizations').insert(data).returning('*');
    return org;
  },

  async list({ page = 1, limit = 20, status }) {
    let query = db('organizations');
    if (status) query = query.where({ status });

    const total = await query.clone().count('id as count').first();
    const p = Math.max(1, parseInt(page, 10));
    const l = Math.min(100, Math.max(1, parseInt(limit, 10)));
    const rows = await query.orderBy('id', 'desc').limit(l).offset((p - 1) * l);

    return { data: rows, pagination: paginationMeta(parseInt(total.count, 10), p, l) };
  },

  async getById(id) {
    const org = await db('organizations').where({ id }).first();
    if (!org) throw ApiError.notFound('Organization not found');
    return org;
  },

  async update(id, data) {
    const [org] = await db('organizations').where({ id }).update({ ...data, updated_at: db.fn.now() }).returning('*');
    if (!org) throw ApiError.notFound('Organization not found');
    return org;
  },

  async deactivate(id) {
    const [org] = await db('organizations').where({ id }).update({ status: 'inactive', updated_at: db.fn.now() }).returning('*');
    if (!org) throw ApiError.notFound('Organization not found');
    // Deactivate all users in this org
    await db('users').where({ organization_id: id }).update({ status: 'inactive', updated_at: db.fn.now() });
    return org;
  },
};

module.exports = organizationService;
