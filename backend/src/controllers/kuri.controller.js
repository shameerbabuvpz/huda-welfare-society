const kuriService = require('../services/kuri.service');

const kuriController = {
  // Group
  async createGroup(req, res, next) {
    try {
      const group = await kuriService.createGroup(req.organizationId, req.body, req.user.id);
      res.status(201).json(group);
    } catch (err) { next(err); }
  },

  async listGroups(req, res, next) {
    try {
      const result = await kuriService.listGroups(req.organizationId, req.query);
      res.json(result);
    } catch (err) { next(err); }
  },

  async getGroup(req, res, next) {
    try {
      const group = await kuriService.getGroup(req.organizationId, parseInt(req.params.id, 10));
      res.json(group);
    } catch (err) { next(err); }
  },

  async updateGroup(req, res, next) {
    try {
      const group = await kuriService.updateGroup(req.organizationId, parseInt(req.params.id, 10), req.body, req.user.id);
      res.json(group);
    } catch (err) { next(err); }
  },

  async deleteGroup(req, res, next) {
    try {
      const result = await kuriService.deleteGroup(req.organizationId, parseInt(req.params.id, 10), req.user.id);
      res.json(result);
    } catch (err) { next(err); }
  },

  // Members
  async addMember(req, res, next) {
    try {
      const km = await kuriService.addMember(req.organizationId, parseInt(req.params.id, 10), req.body.member_id, req.user.id);
      res.status(201).json(km);
    } catch (err) { next(err); }
  },

  async addGuestMember(req, res, next) {
    try {
      const km = await kuriService.addGuestMember(
        req.organizationId,
        parseInt(req.params.id, 10),
        { name: req.body.name, phone: req.body.phone },
        req.user.id
      );
      res.status(201).json(km);
    } catch (err) { next(err); }
  },

  async removeMember(req, res, next) {
    try {
      const km = await kuriService.removeGroupMember(req.organizationId, parseInt(req.params.id, 10), parseInt(req.params.memberId, 10));
      res.json(km);
    } catch (err) { next(err); }
  },

  // Collections
  async recordCollection(req, res, next) {
    try {
      const c = await kuriService.recordCollection(
        req.organizationId,
        parseInt(req.params.id, 10),
        {
          memberId: req.body.member_id,
          monthNumber: req.body.month_number,
          amount: req.body.amount,
          paidDate: req.body.paid_date,
        },
        req.user.id
      );
      res.status(201).json(c);
    } catch (err) { next(err); }
  },

  async getCollections(req, res, next) {
    try {
      const result = await kuriService.getCollections(req.organizationId, parseInt(req.params.id, 10), req.query);
      res.json(result);
    } catch (err) { next(err); }
  },

  // Winner
  async selectWinner(req, res, next) {
    try {
      const w = await kuriService.selectWinner(
        req.organizationId,
        parseInt(req.params.id, 10),
        { memberId: req.body.member_id, monthNumber: req.body.month_number },
        req.user.id
      );
      res.status(201).json(w);
    } catch (err) { next(err); }
  },

  async winnerHistory(req, res, next) {
    try {
      const result = await kuriService.winnerHistory(req.organizationId, parseInt(req.params.id, 10));
      res.json(result);
    } catch (err) { next(err); }
  },

  // Payout
  async recordPayout(req, res, next) {
    try {
      const p = await kuriService.recordPayout(
        req.organizationId,
        parseInt(req.params.id, 10),
        {
          winnerId: req.body.winner_id,
          amount: req.body.amount,
          payoutDate: req.body.payout_date,
          reference: req.body.reference,
        },
        req.user.id
      );
      res.status(201).json(p);
    } catch (err) { next(err); }
  },

  // Member views
  async myKuri(req, res, next) {
    try {
      const db = require('../config/database');
      const member = await db('members').where({ user_id: req.user.id, organization_id: req.organizationId }).first();
      if (!member) return res.status(404).json({ error: { message: 'Member not found' } });
      const result = await kuriService.memberPaymentStatus(req.organizationId, member.id);
      res.json(result);
    } catch (err) { next(err); }
  },
};

module.exports = kuriController;
