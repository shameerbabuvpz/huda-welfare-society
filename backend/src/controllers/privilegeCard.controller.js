const privilegeCardService = require('../services/privilegeCard.service');

const privilegeCardController = {
  async generate(req, res, next) {
    try {
      const card = await privilegeCardService.generate(req.organizationId, parseInt(req.params.memberId, 10));
      res.status(201).json(card);
    } catch (err) { next(err); }
  },

  async getByMember(req, res, next) {
    try {
      const card = await privilegeCardService.getByMember(req.organizationId, parseInt(req.params.memberId, 10));
      res.json(card);
    } catch (err) { next(err); }
  },

  async getMyCard(req, res, next) {
    try {
      const db = require('../config/database');
      const member = await db('members').where({ user_id: req.user.id, organization_id: req.organizationId }).first();
      if (!member) return res.status(404).json({ error: { message: 'Member not found' } });
      const card = await privilegeCardService.getByMember(req.organizationId, member.id);
      res.json(card);
    } catch (err) { next(err); }
  },

  async revoke(req, res, next) {
    try {
      const card = await privilegeCardService.revoke(req.organizationId, parseInt(req.params.cardId, 10));
      res.json(card);
    } catch (err) { next(err); }
  },
};

module.exports = privilegeCardController;
