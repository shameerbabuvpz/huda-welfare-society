const backupService = require('../services/backup.service');
const ApiError = require('../utils/ApiError');

const backupController = {
  async download(req, res, next) {
    try {
      const sql = await backupService.generateSqlDump();
      const ts = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
      res.setHeader('Content-Type', 'application/sql');
      res.setHeader(
        'Content-Disposition',
        `attachment; filename=ayalkoottam-backup-${ts}.sql`
      );
      res.send(sql);
    } catch (err) {
      next(err);
    }
  },

  async restore(req, res, next) {
    try {
      if (!req.file) throw ApiError.badRequest('No backup file uploaded');
      if (req.body.confirm !== 'RESTORE') {
        throw ApiError.badRequest('Restore not confirmed');
      }
      const sql = req.file.buffer.toString('utf8');
      const result = await backupService.restoreFromSql(sql);
      res.json({ message: 'Database restored successfully', ...result });
    } catch (err) {
      next(err);
    }
  },
};

module.exports = backupController;
