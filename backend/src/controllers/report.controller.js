const reportService = require('../services/report.service');

const reportController = {
  async memberSummary(req, res, next) {
    try {
      const result = await reportService.memberSummary(req.organizationId);
      res.json(result);
    } catch (err) { next(err); }
  },

  async assetSummary(req, res, next) {
    try {
      const result = await reportService.assetSummary(req.organizationId);
      res.json(result);
    } catch (err) { next(err); }
  },

  async kuriCollectionSummary(req, res, next) {
    try {
      const result = await reportService.kuriCollectionSummary(req.organizationId, parseInt(req.params.groupId, 10));
      res.json(result);
    } catch (err) { next(err); }
  },

  async kuriPayoutHistory(req, res, next) {
    try {
      const result = await reportService.kuriPayoutHistory(req.organizationId, parseInt(req.params.groupId, 10));
      res.json(result);
    } catch (err) { next(err); }
  },

  async notificationSummary(req, res, next) {
    try {
      const result = await reportService.notificationSummary(req.organizationId);
      res.json(result);
    } catch (err) { next(err); }
  },
};

module.exports = reportController;
