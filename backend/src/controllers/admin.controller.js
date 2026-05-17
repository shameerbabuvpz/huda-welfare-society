const adminService = require('../services/admin.service');

const adminController = {
  async list(req, res, next) {
    try {
      const result = await adminService.list(req.organizationId, req.query);
      res.json(result);
    } catch (err) { next(err); }
  },

  async getById(req, res, next) {
    try {
      const admin = await adminService.getById(req.organizationId, parseInt(req.params.id, 10));
      res.json(admin);
    } catch (err) { next(err); }
  },

  async create(req, res, next) {
    try {
      const admin = await adminService.create(req.organizationId, req.body, req.user.id);
      res.status(201).json(admin);
    } catch (err) { next(err); }
  },

  async update(req, res, next) {
    try {
      const admin = await adminService.update(req.organizationId, parseInt(req.params.id, 10), req.body, req.user.id);
      res.json(admin);
    } catch (err) { next(err); }
  },

  async remove(req, res, next) {
    try {
      await adminService.remove(req.organizationId, parseInt(req.params.id, 10), req.user.id);
      res.json({ message: 'Admin deactivated' });
    } catch (err) { next(err); }
  },
};

module.exports = adminController;
