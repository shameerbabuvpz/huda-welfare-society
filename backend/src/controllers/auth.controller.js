const path = require('path');
const authService = require('../services/auth.service');
const db = require('../config/database');
const ApiError = require('../utils/ApiError');
const { buildPublicUploadUrl, deleteManagedPhoto } = require('../config/uploads');
const { compressProfilePhoto } = require('../utils/imageCompression');

const authController = {
  async requestOtp(req, res, next) {
    try {
      const result = await authService.requestOtp(req.body.phone);
      res.json(result);
    } catch (err) { next(err); }
  },

  async verifyOtp(req, res, next) {
    try {
      const { phone, otp } = req.body;
      const result = await authService.verifyOtp(phone, otp);
      res.json(result);
    } catch (err) { next(err); }
  },

  async switchRole(req, res, next) {
    try {
      const { newRole } = req.body;
      if (!newRole) throw ApiError.badRequest('newRole is required');

      const result = await authService.switchRole(req.user.id, newRole, req.user.organizationId);
      res.json(result);
    } catch (err) { next(err); }
  },

  async updateFcmToken(req, res, next) {
    try {
      await authService.updateFcmToken(req.user.id, req.body.fcm_token);
      res.json({ message: 'FCM token updated' });
    } catch (err) { next(err); }
  },

  async me(req, res, next) {
    try {
      const user = await db('users').where({ id: req.user.id }).first();
      const availableRoles = await authService.getAvailableRoles(user.id);
      
      let orgInfo = null;
      if (user.organization_id) {
        const org = await db('organizations').where({ id: user.organization_id }).first();
        if (org) {
          orgInfo = { id: org.id, name: org.name, place: org.place, logoUrl: org.logo_url, status: org.status };
        }
      }
      res.json({
        user: {
          id: user.id,
          name: user.name,
          phone: user.phone,
          role: user.current_role || user.role,
          roles: availableRoles.length > 0 ? availableRoles : [user.role],
          organizationId: user.organization_id,
          photoUrl: user.photo_url,
          lastLoginAt: user.last_login_at,
        },
        organization: orgInfo,
      });
    } catch (err) { next(err); }
  },

  async updateProfile(req, res, next) {
    try {
      const { name } = req.body;
      const updates = { updated_at: db.fn.now() };
      if (name !== undefined) updates.name = name;

      const [user] = await db('users')
        .where({ id: req.user.id })
        .update(updates)
        .returning('*');

      // Also update member record name if linked
      if (name !== undefined) {
        await db('members')
          .where({ user_id: req.user.id })
          .update({ name, updated_at: db.fn.now() });
      }

      res.json({
        user: {
          id: user.id,
          name: user.name,
          phone: user.phone,
          role: user.role,
          organizationId: user.organization_id,
          photoUrl: user.photo_url,
          lastLoginAt: user.last_login_at,
        },
      });
    } catch (err) { next(err); }
  },

  async updatePhoto(req, res, next) {
    try {
      if (!req.file) throw ApiError.badRequest('Photo file is required');

      // Compress the uploaded photo
      const compressedPath = await compressProfilePhoto(req.file.path);
      const compressedFilename = path.basename(compressedPath);

      const existingUser = await db('users').where({ id: req.user.id }).first();
      const photoUrl = buildPublicUploadUrl(req, `uploads/profile-photos/${compressedFilename}`);

      const [user] = await db('users')
        .where({ id: req.user.id })
        .update({ photo_url: photoUrl, updated_at: db.fn.now() })
        .returning('*');

      deleteManagedPhoto(existingUser?.photo_url);

      res.json({
        user: {
          id: user.id,
          name: user.name,
          phone: user.phone,
          role: user.role,
          organizationId: user.organization_id,
          photoUrl: user.photo_url,
          lastLoginAt: user.last_login_at,
        },
      });
    } catch (err) { next(err); }
  },

  async getOrgInfo(req, res, next) {
    try {
      if (!req.user.organizationId) {
        return res.json({ organization: null });
      }
      const org = await db('organizations').where({ id: req.user.organizationId }).first();
      if (!org) return res.json({ organization: null });
      res.json({
        organization: {
          id: org.id,
          name: org.name,
          place: org.place,
          logoUrl: org.logo_url,
        },
      });
    } catch (err) { next(err); }
  },
};

module.exports = authController;
