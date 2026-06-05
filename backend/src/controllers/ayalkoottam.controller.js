const ayalkoottamService = require('../services/ayalkoottam.service');

const ayalkoottamController = {
  async create(req, res, next) {
    try {
      const ak = await ayalkoottamService.create(req.organizationId, req.body, req.user.id);
      res.status(201).json(ak);
    } catch (err) { next(err); }
  },

  async list(req, res, next) {
    try {
      const result = await ayalkoottamService.list(req.organizationId, req.query);
      res.json(result);
    } catch (err) { next(err); }
  },

  async getById(req, res, next) {
    try {
      const ak = await ayalkoottamService.getById(req.organizationId, parseInt(req.params.id, 10));
      res.json(ak);
    } catch (err) { next(err); }
  },

  async update(req, res, next) {
    try {
      const ak = await ayalkoottamService.update(req.organizationId, parseInt(req.params.id, 10), req.body, req.user.id);
      res.json(ak);
    } catch (err) { next(err); }
  },

  async deactivate(req, res, next) {
    try {
      const ak = await ayalkoottamService.deactivate(req.organizationId, parseInt(req.params.id, 10), req.user.id);
      res.json(ak);
    } catch (err) { next(err); }
  },

  async listAll(req, res, next) {
    try {
      const list = await ayalkoottamService.listAll(req.organizationId);
      res.json(list);
    } catch (err) { next(err); }
  },

  async leaders(req, res, next) {
    try {
      const list = await ayalkoottamService.getLeaders(req.organizationId);
      res.json({ data: list });
    } catch (err) { next(err); }
  },
};

module.exports = ayalkoottamController;
