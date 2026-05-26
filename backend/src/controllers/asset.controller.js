const assetService = require('../services/asset.service');

const assetController = {
  async create(req, res, next) {
    try {
      const asset = await assetService.create(req.organizationId, req.body, req.user.id);
      res.status(201).json(asset);
    } catch (err) { next(err); }
  },

  async list(req, res, next) {
    try {
      const result = await assetService.list(req.organizationId, req.query);
      res.json(result);
    } catch (err) { next(err); }
  },

  async listAvailable(req, res, next) {
    try {
      const assets = await assetService.listAvailable(req.organizationId, req.query);
      res.json(assets);
    } catch (err) { next(err); }
  },

  async getById(req, res, next) {
    try {
      const asset = await assetService.getById(req.organizationId, parseInt(req.params.id, 10));
      res.json(asset);
    } catch (err) { next(err); }
  },

  async update(req, res, next) {
    try {
      const asset = await assetService.update(req.organizationId, parseInt(req.params.id, 10), req.body, req.user.id);
      res.json(asset);
    } catch (err) { next(err); }
  },

  async issue(req, res, next) {
    try {
      const txn = await assetService.issue(
        req.organizationId,
        parseInt(req.params.id, 10),
        { memberId: req.body.member_id, dueDate: req.body.due_date, remarks: req.body.remarks },
        req.user.id
      );
      res.status(201).json(txn);
    } catch (err) { next(err); }
  },

  async returnAsset(req, res, next) {
    try {
      const txn = await assetService.returnAsset(
        req.organizationId,
        parseInt(req.params.id, 10),
        { remarks: req.body.remarks, conditionOnReturn: req.body.condition_on_return },
        req.user.id
      );
      res.json(txn);
    } catch (err) { next(err); }
  },

  async history(req, res, next) {
    try {
      const result = await assetService.transactionHistory(req.organizationId, parseInt(req.params.id, 10), req.query);
      res.json(result);
    } catch (err) { next(err); }
  },

  async issueRegister(req, res, next) {
    try {
      const result = await assetService.issueRegister(req.organizationId, req.query);
      res.json(result);
    } catch (err) { next(err); }
  },

  async damageReport(req, res, next) {
    try {
      const result = await assetService.damageReport(req.organizationId, req.query);
      res.json(result);
    } catch (err) { next(err); }
  },

  async stats(req, res, next) {
    try {
      const result = await assetService.stats(req.organizationId);
      res.json(result);
    } catch (err) { next(err); }
  },

  async myAssets(req, res, next) {
    try {
      const db = require('../config/database');
      const member = await db('members').where({ user_id: req.user.id, organization_id: req.organizationId }).first();
      if (!member) return res.status(404).json({ error: { message: 'Member not found' } });
      const assets = await assetService.memberAssets(req.organizationId, member.id);
      res.json(assets);
    } catch (err) { next(err); }
  },

  async delete(req, res, next) {
    try {
      await assetService.delete(req.organizationId, parseInt(req.params.id, 10), req.user.id);
      res.json({ message: 'Asset deleted successfully' });
    } catch (err) { next(err); }
  },
};

module.exports = assetController;
