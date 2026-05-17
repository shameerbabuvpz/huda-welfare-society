const db = require('../config/database');
const ApiError = require('../utils/ApiError');

const bannerService = {
  async create(orgId, data, actorId) {
    const [banner] = await db('banners').insert({
      organization_id: orgId,
      title: data.title,
      image_url: data.image_url,
      sort_order: data.sort_order || 0,
      is_active: true,
      created_by: actorId,
      updated_by: actorId,
    }).returning('*');
    return banner;
  },

  async list(orgId) {
    return db('banners')
      .where({ organization_id: orgId })
      .orderBy('sort_order')
      .orderBy('created_at', 'desc');
  },

  async getById(orgId, id) {
    const banner = await db('banners').where({ id, organization_id: orgId }).first();
    if (!banner) throw ApiError.notFound('Banner not found');
    return banner;
  },

  async update(orgId, id, data, actorId) {
    const allowed = {};
    if (data.title !== undefined) allowed.title = data.title;
    if (data.image_url !== undefined) allowed.image_url = data.image_url;
    if (data.sort_order !== undefined) allowed.sort_order = data.sort_order;
    if (data.is_active !== undefined) allowed.is_active = data.is_active;

    const [banner] = await db('banners')
      .where({ id, organization_id: orgId })
      .update({ ...allowed, updated_by: actorId, updated_at: db.fn.now() })
      .returning('*');
    if (!banner) throw ApiError.notFound('Banner not found');
    return banner;
  },

  async delete(orgId, id) {
    const deleted = await db('banners').where({ id, organization_id: orgId }).del();
    if (!deleted) throw ApiError.notFound('Banner not found');
    return { success: true };
  },

  async listActive(orgId) {
    return db('banners')
      .where({ organization_id: orgId, is_active: true })
      .orderBy('sort_order')
      .orderBy('created_at', 'desc');
  },
};

module.exports = bannerService;
