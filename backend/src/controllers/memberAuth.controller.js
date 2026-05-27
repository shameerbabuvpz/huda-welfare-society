const path = require('path');
const memberAuthService = require('../services/memberAuth.service');
const db = require('../config/database');
const ApiError = require('../utils/ApiError');
const { buildPublicUploadUrl, deleteManagedPhoto } = require('../config/uploads');
const { compressProfilePhoto } = require('../utils/imageCompression');

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
   * Request OTP for member phone login
   * Body: { phone }
   */
  async requestPhoneOtp(req, res, next) {
    try {
      const { phone } = req.body;

      if (!phone) {
        return res.status(400).json({
          success: false,
          message: 'Missing required field: phone',
        });
      }

      const result = await memberAuthService.requestPhoneOtp(phone);
      res.json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  },

  /**
   * Verify OTP and login member by phone
   * Body: { phone, otp }
   */
  async verifyPhoneOtp(req, res, next) {
    try {
      const { phone, otp } = req.body;

      if (!phone || !otp) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: phone, otp',
        });
      }

      const result = await memberAuthService.loginWithPhone(phone, otp);
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

  /**
   * Update member profile photo
   * Requires: member authentication + multipart photo upload
   */
  async updatePhoto(req, res, next) {
    try {
      if (!req.file) {
        return res.status(400).json({ success: false, message: 'Photo file is required' });
      }

      const memberId = req.member.id;
      const organizationId = req.member.organizationId;

      // Compress the uploaded photo
      const compressedPath = await compressProfilePhoto(req.file.path);
      const compressedFilename = path.basename(compressedPath);

      const existingMember = await db('members').where({ id: memberId, organization_id: organizationId }).first();
      const photoUrl = buildPublicUploadUrl(req, `uploads/profile-photos/${compressedFilename}`);

      await db('members')
        .where({ id: memberId })
        .update({ photo_url: photoUrl, updated_at: db.fn.now() });

      // Also update user photo if linked
      if (existingMember.user_id) {
        await db('users')
          .where({ id: existingMember.user_id })
          .update({ photo_url: photoUrl, updated_at: db.fn.now() });
      }

      // Delete old photo
      deleteManagedPhoto(existingMember?.photo_url);

      res.json({ success: true, photoUrl });
    } catch (err) {
      next(err);
    }
  },
};

module.exports = memberAuthController;
