const exportService = require('../services/export.service');
const ApiError = require('../utils/ApiError');

const exportController = {
  async membersExcel(req, res, next) {
    try {
      const { ayalkoottam_id } = req.query;
      const buffer = await exportService.membersToExcel(req.organizationId, {
        ayalkoottamId: ayalkoottam_id ? parseInt(ayalkoottam_id, 10) : undefined,
      });
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', 'attachment; filename=members.xlsx');
      res.send(Buffer.from(buffer));
    } catch (err) { next(err); }
  },

  async membersPdf(req, res, next) {
    try {
      const { ayalkoottam_id } = req.query;
      const buffer = await exportService.membersToPdf(req.organizationId, {
        ayalkoottamId: ayalkoottam_id ? parseInt(ayalkoottam_id, 10) : undefined,
      });
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'attachment; filename=members.pdf');
      res.send(buffer);
    } catch (err) { next(err); }
  },

  async kuriExcel(req, res, next) {
    try {
      const groupId = parseInt(req.params.groupId, 10);
      const buffer = await exportService.kuriToExcel(req.organizationId, groupId);
      if (!buffer) throw ApiError.notFound('Kuri group not found');
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', 'attachment; filename=kuri-report.xlsx');
      res.send(Buffer.from(buffer));
    } catch (err) { next(err); }
  },

  async kuriPdf(req, res, next) {
    try {
      const groupId = parseInt(req.params.groupId, 10);
      const buffer = await exportService.kuriToPdf(req.organizationId, groupId);
      if (!buffer) throw ApiError.notFound('Kuri group not found');
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'attachment; filename=kuri-report.pdf');
      res.send(buffer);
    } catch (err) { next(err); }
  },

  async kaneevExcel(req, res, next) {
    try {
      const buffer = await exportService.kaneevToExcel(req.organizationId);
      if (!buffer) throw ApiError.notFound('No kaneev data found');
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', 'attachment; filename=kaneev-report.xlsx');
      res.send(Buffer.from(buffer));
    } catch (err) { next(err); }
  },

  async kaneevPdf(req, res, next) {
    try {
      const buffer = await exportService.kaneevToPdf(req.organizationId);
      if (!buffer) throw ApiError.notFound('No kaneev data found');
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'attachment; filename=kaneev-report.pdf');
      res.send(buffer);
    } catch (err) { next(err); }
  },

  async financeExcel(req, res, next) {
    try {
      const { from_date, to_date } = req.query;
      const buffer = await exportService.financeToExcel(req.organizationId, {
        fromDate: from_date, toDate: to_date,
      });
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', 'attachment; filename=finance-report.xlsx');
      res.send(Buffer.from(buffer));
    } catch (err) { next(err); }
  },

  async financePdf(req, res, next) {
    try {
      const { from_date, to_date } = req.query;
      const buffer = await exportService.financeToPdf(req.organizationId, {
        fromDate: from_date, toDate: to_date,
      });
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'attachment; filename=finance-report.pdf');
      res.send(buffer);
    } catch (err) { next(err); }
  },

  async leadersExcel(req, res, next) {
    try {
      const buffer = await exportService.leadersToExcel(req.organizationId);
      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', 'attachment; filename=office-bearers.xlsx');
      res.send(Buffer.from(buffer));
    } catch (err) { next(err); }
  },

  async leadersPdf(req, res, next) {
    try {
      const buffer = await exportService.leadersToPdf(req.organizationId);
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'attachment; filename=office-bearers.pdf');
      res.send(buffer);
    } catch (err) { next(err); }
  },
};

module.exports = exportController;
