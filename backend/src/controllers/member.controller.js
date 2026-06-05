const memberService = require('../services/member.service');

const memberController = {
  async create(req, res, next) {
    try {
      const member = await memberService.create(req.organizationId, req.body, req.user.id);
      res.status(201).json(member);
    } catch (err) { next(err); }
  },

  async list(req, res, next) {
    try {
      const result = await memberService.list(req.organizationId, req.query);
      res.json(result);
    } catch (err) { next(err); }
  },

  async getById(req, res, next) {
    try {
      const member = await memberService.getById(req.organizationId, parseInt(req.params.id, 10));
      res.json(member);
    } catch (err) { next(err); }
  },

  async update(req, res, next) {
    try {
      const member = await memberService.update(req.organizationId, parseInt(req.params.id, 10), req.body, req.user.id);
      res.json(member);
    } catch (err) { next(err); }
  },

  async remove(req, res, next) {
    try {
      await memberService.softDelete(req.organizationId, parseInt(req.params.id, 10), req.user.id);
      res.json({ message: 'Member deactivated' });
    } catch (err) { next(err); }
  },

  async profile(req, res, next) {
    try {
      const member = await memberService.getProfile(req.organizationId, req.user.id);
      res.json(member);
    } catch (err) { next(err); }
  },

  async myAyalkoottamMembers(req, res, next) {
    try {
      const result = await memberService.listMyAyalkoottam(req.organizationId, req.user.id, req.query);
      res.json(result);
    } catch (err) { next(err); }
  },

  async checkDesignation(req, res, next) {
    try {
      const { ayalkoottam_id, designation } = req.query;
      const result = await memberService.checkDesignation(req.organizationId, parseInt(ayalkoottam_id, 10), designation);
      res.json(result);
    } catch (err) { next(err); }
  },
};

module.exports = memberController;
