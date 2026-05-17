const organizationService = require('../services/organization.service');
const db = require('../config/database');
const ApiError = require('../utils/ApiError');

const organizationController = {
  async create(req, res, next) {
    try {
      const org = await organizationService.create(req.body);
      res.status(201).json(org);
    } catch (err) { next(err); }
  },

  async list(req, res, next) {
    try {
      const result = await organizationService.list(req.query);
      res.json(result);
    } catch (err) { next(err); }
  },

  async getById(req, res, next) {
    try {
      const org = await organizationService.getById(parseInt(req.params.id, 10));
      res.json(org);
    } catch (err) { next(err); }
  },

  async update(req, res, next) {
    try {
      const org = await organizationService.update(parseInt(req.params.id, 10), req.body);
      res.json(org);
    } catch (err) { next(err); }
  },

  async uploadLogo(req, res, next) {
    try {
      const orgId = parseInt(req.params.id, 10);
      if (!req.file) throw ApiError.badRequest('Logo file is required');
      const { buildPublicUploadUrl } = require('../config/uploads');
      const logoUrl = buildPublicUploadUrl(req, `uploads/org-logos/${req.file.filename}`);
      const org = await organizationService.update(orgId, { logo_url: logoUrl });
      res.json(org);
    } catch (err) { next(err); }
  },

  async deactivate(req, res, next) {
    try {
      const org = await organizationService.deactivate(parseInt(req.params.id, 10));
      res.json(org);
    } catch (err) { next(err); }
  },

  // ── Add admin user to an organization ──
  async addAdmin(req, res, next) {
    try {
      const orgId = parseInt(req.params.id, 10);
      const { phone, name } = req.body;

      const org = await db('organizations').where({ id: orgId }).first();
      if (!org) throw ApiError.notFound('Organization not found');

      // Check if user already exists with this phone
      let user = await db('users').where({ phone }).first();
      if (user) {
        if (user.organization_id === orgId && user.role === 'admin') {
          throw ApiError.conflict('Admin already exists for this organization');
        }
        // Update existing user to admin of this org
        [user] = await db('users')
          .where({ id: user.id })
          .update({ role: 'admin', organization_id: orgId, name: name || user.name, status: 'active', updated_at: db.fn.now() })
          .returning('*');
      } else {
        // Create new admin user
        [user] = await db('users').insert({
          phone,
          name: name || 'Admin',
          role: 'admin',
          organization_id: orgId,
          status: 'active',
        }).returning('*');
      }

      res.status(201).json({
        id: user.id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        organizationId: user.organization_id,
      });
    } catch (err) { next(err); }
  },

  // ── List admins for an organization ──
  async listAdmins(req, res, next) {
    try {
      const orgId = parseInt(req.params.id, 10);
      const admins = await db('users')
        .where({ organization_id: orgId, role: 'admin', status: 'active' })
        .select('id', 'name', 'phone', 'role', 'organization_id as organizationId');
      res.json(admins);
    } catch (err) { next(err); }
  },
};

module.exports = organizationController;
