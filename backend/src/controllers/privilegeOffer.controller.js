const privilegeOfferService = require('../services/privilegeOffer.service');
const { buildPublicUploadUrl } = require('../config/uploads');

const privilegeOfferController = {
  // ── Admin ──
  async create(req, res, next) {
    try {
      const data = { ...req.body };
      if (req.files?.logo?.[0]) {
        data.logo_url = buildPublicUploadUrl(req, `uploads/privilege-offers/${req.files.logo[0].filename}`);
      }
      if (req.files?.image?.[0]) {
        data.image_url = buildPublicUploadUrl(req, `uploads/privilege-offers/${req.files.image[0].filename}`);
      }
      const offer = await privilegeOfferService.create(req.organizationId, data, req.user.id);
      res.status(201).json(offer);
    } catch (err) { next(err); }
  },

  async list(req, res, next) {
    try {
      const offers = await privilegeOfferService.list(req.organizationId, { status: req.query.status });
      res.json(offers);
    } catch (err) { next(err); }
  },

  async getById(req, res, next) {
    try {
      const offer = await privilegeOfferService.getById(req.organizationId, parseInt(req.params.id, 10));
      res.json(offer);
    } catch (err) { next(err); }
  },

  async update(req, res, next) {
    try {
      const data = { ...req.body };
      if (req.files?.logo?.[0]) {
        data.logo_url = buildPublicUploadUrl(req, `uploads/privilege-offers/${req.files.logo[0].filename}`);
      }
      if (req.files?.image?.[0]) {
        data.image_url = buildPublicUploadUrl(req, `uploads/privilege-offers/${req.files.image[0].filename}`);
      }
      const offer = await privilegeOfferService.update(req.organizationId, parseInt(req.params.id, 10), data, req.user.id);
      res.json(offer);
    } catch (err) { next(err); }
  },

  async delete(req, res, next) {
    try {
      await privilegeOfferService.delete(req.organizationId, parseInt(req.params.id, 10));
      res.json({ success: true });
    } catch (err) { next(err); }
  },

  // ── Member ──
  async listActive(req, res, next) {
    try {
      const offers = await privilegeOfferService.listActive(req.organizationId);
      res.json(offers);
    } catch (err) { next(err); }
  },

  async redeem(req, res, next) {
    try {
      const db = require('../config/database');
      const member = await db('members').where({ user_id: req.user.id, organization_id: req.organizationId }).first();
      if (!member) return res.status(404).json({ error: { message: 'Member not found' } });

      const result = await privilegeOfferService.redeem(req.organizationId, req.body.qr_code, member.id);
      res.status(201).json(result);
    } catch (err) { next(err); }
  },

  async myRedemptions(req, res, next) {
    try {
      const db = require('../config/database');
      const member = await db('members').where({ user_id: req.user.id, organization_id: req.organizationId }).first();
      if (!member) return res.status(404).json({ error: { message: 'Member not found' } });

      const redemptions = await privilegeOfferService.myRedemptions(req.organizationId, member.id);
      res.json(redemptions);
    } catch (err) { next(err); }
  },
};

module.exports = privilegeOfferController;
