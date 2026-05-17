const infaccSyncService = require('../services/infaccSync.service');

const infaccSyncController = {
  async sync(req, res, next) {
    try {
      const result = await infaccSyncService.sync(req.organizationId);
      if (!result.success) {
        const status = result.error === 'LOGIN_FAILED' ? 401 : 400;
        return res.status(status).json(result);
      }
      res.json(result);
    } catch (err) { next(err); }
  },

  async setCredentials(req, res, next) {
    try {
      const { phone, password } = req.body;
      if (!phone || !password) {
        return res.status(400).json({ error: { message: 'Phone and password are required' } });
      }
      await infaccSyncService.setCredentials(req.organizationId, phone.trim(), password);
      res.json({ message: 'INFACC credentials saved' });
    } catch (err) { next(err); }
  },

  async getStatus(req, res, next) {
    try {
      const lastSync = await infaccSyncService.getLastSync(req.organizationId);
      const creds = await infaccSyncService.getCredentials(req.organizationId);
      res.json({ hasCredentials: !!(creds.phone && creds.password), infaccPhone: creds.phone || null, lastSync });
    } catch (err) { next(err); }
  },
};

module.exports = infaccSyncController;
