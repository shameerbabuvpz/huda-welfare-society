const memberAuthService = require('../services/memberAuth.service');

const memberAuthController = {
  /**
   * Member login with code
   * Body: { memberId, organizationId, code }
   */
  async loginWithCode(req, res, next) {
    try {
      const { memberId, organizationId, code } = req.body;
      
      if (!memberId || !organizationId || !code) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: memberId, organizationId, code',
        });
      }

      const result = await memberAuthService.loginWithCode(organizationId, memberId, code);
      res.json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  },

  /**
   * Change member's login code
   * Requires: member authentication
   * Body: { currentCode, newCode }
   */
  async changeCode(req, res, next) {
    try {
      const { currentCode, newCode } = req.body;
      const memberId = req.member.id; // Set by member auth middleware
      const organizationId = req.member.organizationId;

      if (!currentCode || !newCode) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: currentCode, newCode',
        });
      }

      const result = await memberAuthService.changeCode(
        organizationId,
        memberId,
        currentCode,
        newCode,
      );

      res.json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  },

  /**
   * Reset member code to default (Admin function)
   * Requires: admin authentication
   * Body: { memberId }
   */
  async resetCodeToDefault(req, res, next) {
    try {
      const { memberId } = req.body;
      const organizationId = req.organizationId; // Set by auth middleware
      const adminId = req.user.id; // Set by auth middleware

      if (!memberId) {
        return res.status(400).json({
          success: false,
          message: 'Missing required field: memberId',
        });
      }

      const result = await memberAuthService.resetCodeToDefault(organizationId, memberId);

      // Log the action
      console.log(`Admin ${adminId} reset code for member ${memberId}`);

      res.json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  },

  /**
   * Get member code status (Admin view)
   * Requires: admin authentication
   */
  async getCodeStatus(req, res, next) {
    try {
      const memberId = parseInt(req.params.memberId, 10);
      const organizationId = req.organizationId;

      const result = await memberAuthService.getMemberCodeStatus(organizationId, memberId);
      res.json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  },

  /**
   * Get member profile (for authenticated members)
   */
  async getProfile(req, res, next) {
    try {
      const memberId = req.member.id;
      const organizationId = req.member.organizationId;

      const profile = await memberAuthService.getProfile(organizationId, memberId);
      res.json({ success: true, member: profile });
    } catch (err) {
      next(err);
    }
  },
};

module.exports = memberAuthController;
