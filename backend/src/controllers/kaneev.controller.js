const kaneevService = require('../services/kaneev.service');

const kaneevController = {
  // Single group – auto-create or get
  async getGroup(req, res, next) {
    try {
      const group = await kaneevService.getOrCreateGroup(req.organizationId, req.user.id);
      const detail = await kaneevService.getGroupDetail(req.organizationId, group.id);
      res.json(detail);
    } catch (err) { next(err); }
  },

  async updateGroup(req, res, next) {
    try {
      const group = await kaneevService.getOrCreateGroup(req.organizationId, req.user.id);
      const updated = await kaneevService.updateGroup(req.organizationId, group.id, req.body, req.user.id);
      res.json(updated);
    } catch (err) { next(err); }
  },

  // Members
  async addMember(req, res, next) {
    try {
      const group = await kaneevService.getOrCreateGroup(req.organizationId, req.user.id);
      const km = await kaneevService.addMember(req.organizationId, group.id, req.body.member_id, req.user.id);
      res.status(201).json(km);
    } catch (err) { next(err); }
  },

  async removeMember(req, res, next) {
    try {
      const group = await kaneevService.getOrCreateGroup(req.organizationId, req.user.id);
      const km = await kaneevService.removeMember(req.organizationId, group.id, parseInt(req.params.memberId, 10));
      res.json(km);
    } catch (err) { next(err); }
  },

  async setMemberStatus(req, res, next) {
    try {
      const group = await kaneevService.getOrCreateGroup(req.organizationId, req.user.id);
      const km = await kaneevService.setMemberStatus(
        req.organizationId,
        group.id,
        parseInt(req.params.memberId, 10),
        req.body.status,
      );
      res.json(km);
    } catch (err) { next(err); }
  },

  // Donations
  async recordDonation(req, res, next) {
    try {
      const group = await kaneevService.getOrCreateGroup(req.organizationId, req.user.id);
      const d = await kaneevService.recordDonation(
        req.organizationId,
        group.id,
        {
          memberId: req.body.member_id,
          monthNumber: req.body.month_number,
          amount: req.body.amount,
          paidDate: req.body.paid_date,
        },
        req.user.id
      );
      res.status(201).json(d);
    } catch (err) { next(err); }
  },

  async getDonations(req, res, next) {
    try {
      const group = await kaneevService.getOrCreateGroup(req.organizationId, req.user.id);
      const result = await kaneevService.getDonations(req.organizationId, group.id, req.query);
      res.json(result);
    } catch (err) { next(err); }
  },

  // Recipients
  async selectRecipient(req, res, next) {
    try {
      const group = await kaneevService.getOrCreateGroup(req.organizationId, req.user.id);
      const r = await kaneevService.selectRecipient(
        req.organizationId,
        group.id,
        { memberId: req.body.member_id, monthNumber: req.body.month_number, amount: req.body.amount },
        req.user.id
      );
      res.status(201).json(r);
    } catch (err) { next(err); }
  },

  async recipientHistory(req, res, next) {
    try {
      const group = await kaneevService.getOrCreateGroup(req.organizationId, req.user.id);
      const result = await kaneevService.recipientHistory(req.organizationId, group.id);
      res.json(result);
    } catch (err) { next(err); }
  },

  // Balance
  async getBalanceHistory(req, res, next) {
    try {
      const group = await kaneevService.getOrCreateGroup(req.organizationId, req.user.id);
      const result = await kaneevService.getBalanceHistory(req.organizationId, group.id);
      res.json(result);
    } catch (err) { next(err); }
  },

  // Member self-service
  async myKaneev(req, res, next) {
    try {
      const db = require('../config/database');
      const member = await db('members').where({ user_id: req.user.id, organization_id: req.organizationId }).first();
      if (!member) return res.status(404).json({ error: { message: 'Member not found' } });
      const result = await kaneevService.myKaneev(req.organizationId, member.id);
      res.json(result);
    } catch (err) { next(err); }
  },
};

module.exports = kaneevController;
