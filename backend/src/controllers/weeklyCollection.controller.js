const weeklyCollectionService = require('../services/weeklyCollection.service');

const weeklyCollectionController = {
  async upsert(req, res, next) {
    try {
      const row = await weeklyCollectionService.upsert(req.organizationId, req.body, req.user.id);
      res.status(201).json(row);
    } catch (err) { next(err); }
  },

  async list(req, res, next) {
    try {
      const result = await weeklyCollectionService.list(req.organizationId, req.query);
      res.json(result);
    } catch (err) { next(err); }
  },

  async getById(req, res, next) {
    try {
      const row = await weeklyCollectionService.getById(req.organizationId, parseInt(req.params.id, 10));
      res.json(row);
    } catch (err) { next(err); }
  },

  async update(req, res, next) {
    try {
      const row = await weeklyCollectionService.update(req.organizationId, parseInt(req.params.id, 10), req.body, req.user.id);
      res.json(row);
    } catch (err) { next(err); }
  },

  async remove(req, res, next) {
    try {
      const result = await weeklyCollectionService.remove(req.organizationId, parseInt(req.params.id, 10), req.user.id);
      res.json(result);
    } catch (err) { next(err); }
  },

  async consolidated(req, res, next) {
    try {
      const report = await weeklyCollectionService.getConsolidated(req.organizationId, req.query);
      res.json(report);
    } catch (err) { next(err); }
  },

  async getBalance(req, res, next) {
    try {
      const { ayalkoottam_id } = req.params;
      const { before_week } = req.query;
      const result = await weeklyCollectionService.getBalance(
        req.organizationId,
        parseInt(ayalkoottam_id, 10),
        before_week || null
      );
      res.json(result);
    } catch (err) { next(err); }
  },
};

module.exports = weeklyCollectionController;
