const db = require('../config/database');
const ApiError = require('../utils/ApiError');
const { paginationMeta } = require('../utils/pagination');
const auditService = require('./audit.service');

const ayalkoottamService = {
  async create(orgId, data, actorId) {
    const existing = await db('ayalkoottams').where({ organization_id: orgId, name: data.name }).first();
    if (existing) throw ApiError.conflict('ഈ പേരിൽ ഒരു അയൽക്കൂട്ടം ഇതിനകം ഉണ്ട്');

    const [ak] = await db('ayalkoottams').insert({
      organization_id: orgId,
      name: data.name,
      code: data.name,
      place: data.place || null,
      status: 'active',
      created_by: actorId,
      updated_by: actorId,
    }).returning('*');

    await auditService.log({
      organizationId: orgId,
      actorId,
      action: 'ayalkoottam.create',
      entityType: 'ayalkoottam',
      entityId: ak.id,
      details: { name: data.name },
    });

    return ak;
  },

  async list(orgId, { page = 1, limit = 20, status, search }) {
    let query = db('ayalkoottams').where({ organization_id: orgId });
    if (status) query = query.andWhere({ status });
    if (search) {
      query = query.andWhere(function () {
        this.where('name', 'ilike', `%${search}%`)
          .orWhere('place', 'ilike', `%${search}%`);
      });
    }

    const total = await query.clone().count('id as count').first();
    const p = Math.max(1, parseInt(page, 10));
    const l = Math.min(100, Math.max(1, parseInt(limit, 10)));
    const rows = await query.orderBy('name', 'asc').limit(l).offset((p - 1) * l);

    // Attach member count for each ayalkoottam
    const ids = rows.map(r => r.id);
    const memberCounts = await db('members')
      .whereIn('ayalkoottam_id', ids)
      .andWhere({ status: 'active' })
      .select('ayalkoottam_id')
      .count('id as count')
      .groupBy('ayalkoottam_id');

    const countMap = {};
    memberCounts.forEach(mc => { countMap[mc.ayalkoottam_id] = parseInt(mc.count, 10); });
    const data = rows.map(r => ({ ...r, member_count: countMap[r.id] || 0 }));

    return { data, pagination: paginationMeta(parseInt(total.count, 10), p, l) };
  },

  async getById(orgId, id) {
    const ak = await db('ayalkoottams').where({ id, organization_id: orgId }).first();
    if (!ak) throw ApiError.notFound('Ayalkoottam not found');

    const memberCount = await db('members')
      .where({ ayalkoottam_id: id, status: 'active' })
      .count('id as count')
      .first();
    ak.member_count = parseInt(memberCount.count, 10);

    return ak;
  },

  async update(orgId, id, data, actorId) {
    const [ak] = await db('ayalkoottams')
      .where({ id, organization_id: orgId })
      .update({
        ...data,
        updated_by: actorId,
        updated_at: db.fn.now(),
      })
      .returning('*');
    if (!ak) throw ApiError.notFound('Ayalkoottam not found');

    await auditService.log({
      organizationId: orgId,
      actorId,
      action: 'ayalkoottam.update',
      entityType: 'ayalkoottam',
      entityId: id,
      details: data,
    });

    return ak;
  },

  async deactivate(orgId, id, actorId) {
    const [ak] = await db('ayalkoottams')
      .where({ id, organization_id: orgId })
      .update({ status: 'inactive', updated_by: actorId, updated_at: db.fn.now() })
      .returning('*');
    if (!ak) throw ApiError.notFound('Ayalkoottam not found');

    await auditService.log({
      organizationId: orgId,
      actorId,
      action: 'ayalkoottam.deactivate',
      entityType: 'ayalkoottam',
      entityId: id,
    });

    return ak;
  },

  async listAll(orgId) {
    return db('ayalkoottams')
      .where({ organization_id: orgId, status: 'active' })
      .select('id', 'name', 'place')
      .orderBy('name');
  },

  /**
   * Office-bearers directory: every active ayalkoottam with its president and
   * secretary (name, member code/id and phone).
   */
  async getLeaders(orgId) {
    const ayalkoottams = await db('ayalkoottams')
      .where({ organization_id: orgId, status: 'active' })
      .select('id', 'name', 'place')
      .orderBy('name');

    const leaders = await db('members')
      .where({ organization_id: orgId, status: 'active' })
      .whereIn('designation', ['president', 'secretary'])
      .whereNotNull('ayalkoottam_id')
      .select('id', 'ayalkoottam_id', 'name', 'member_code', 'phone', 'designation');

    const byAk = {};
    leaders.forEach((l) => {
      byAk[l.ayalkoottam_id] = byAk[l.ayalkoottam_id] || {};
      byAk[l.ayalkoottam_id][l.designation] = l;
    });

    return ayalkoottams.map((ak) => {
      const president = byAk[ak.id] && byAk[ak.id].president;
      const secretary = byAk[ak.id] && byAk[ak.id].secretary;
      return {
        ayalkoottam_id: ak.id,
        ayalkoottam_name: ak.name,
        place: ak.place || '',
        president_name: president ? president.name : '',
        president_code: president ? president.member_code : '',
        president_phone: president ? president.phone || '' : '',
        secretary_name: secretary ? secretary.name : '',
        secretary_code: secretary ? secretary.member_code : '',
        secretary_phone: secretary ? secretary.phone || '' : '',
      };
    });
  },
};

module.exports = ayalkoottamService;
