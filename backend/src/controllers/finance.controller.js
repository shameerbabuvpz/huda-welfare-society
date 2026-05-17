const financeService = require('../services/finance.service');

const financeController = {
  // ─── Categories ───────────────────────────────────────────────
  async createCategory(req, res, next) {
    try {
      const category = await financeService.createCategory(req.organizationId, req.body, req.user.id);
      res.status(201).json(category);
    } catch (err) { next(err); }
  },

  async listCategories(req, res, next) {
    try {
      const categories = await financeService.listCategories(req.organizationId, req.query);
      res.json(categories);
    } catch (err) { next(err); }
  },

  async deleteCategory(req, res, next) {
    try {
      const result = await financeService.deleteCategory(req.organizationId, parseInt(req.params.id, 10));
      res.json(result);
    } catch (err) { next(err); }
  },

  // ─── Transactions ─────────────────────────────────────────────
  async createTransaction(req, res, next) {
    try {
      const txn = await financeService.createTransaction(req.organizationId, req.body, req.user.id);
      res.status(201).json(txn);
    } catch (err) { next(err); }
  },

  async listTransactions(req, res, next) {
    try {
      const result = await financeService.listTransactions(req.organizationId, req.query);
      res.json(result);
    } catch (err) { next(err); }
  },

  async deleteTransaction(req, res, next) {
    try {
      const result = await financeService.deleteTransaction(req.organizationId, parseInt(req.params.id, 10), req.user.id);
      res.json(result);
    } catch (err) { next(err); }
  },

  async getSummary(req, res, next) {
    try {
      const summary = await financeService.getSummary(req.organizationId, req.query);
      res.json(summary);
    } catch (err) { next(err); }
  },
};

module.exports = financeController;
