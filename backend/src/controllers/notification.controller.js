const notificationService = require('../services/notification.service');

const notificationController = {
  async send(req, res, next) {
    try {
      const result = await notificationService.send(
        req.organizationId,
        {
          title: req.body.title,
          body: req.body.body,
          audienceType: req.body.audience_type,
          memberIds: req.body.member_ids,
        },
        req.user.id
      );
      res.status(201).json(result);
    } catch (err) { next(err); }
  },

  async list(req, res, next) {
    try {
      const result = await notificationService.list(req.organizationId, req.query);
      res.json(result);
    } catch (err) { next(err); }
  },

  async update(req, res, next) {
    try {
      const result = await notificationService.update(
        req.organizationId,
        parseInt(req.params.id, 10),
        { title: req.body.title, body: req.body.body }
      );
      res.json(result);
    } catch (err) { next(err); }
  },

  async delete(req, res, next) {
    try {
      const result = await notificationService.delete(req.organizationId, parseInt(req.params.id, 10));
      res.json(result);
    } catch (err) { next(err); }
  },

  async deliveryLogs(req, res, next) {
    try {
      const logs = await notificationService.getDeliveryLogs(req.organizationId, parseInt(req.params.id, 10));
      res.json(logs);
    } catch (err) { next(err); }
  },

  async myNotifications(req, res, next) {
    try {
      const db = require('../config/database');
      const member = await db('members').where({ user_id: req.user.id, organization_id: req.organizationId }).first();
      if (!member) return res.status(404).json({ error: { message: 'Member not found' } });
      const result = await notificationService.memberNotifications(req.organizationId, member.id, req.query);
      res.json(result);
    } catch (err) { next(err); }
  },
};

module.exports = notificationController;
