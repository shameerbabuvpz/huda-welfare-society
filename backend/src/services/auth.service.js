const jwt = require('jsonwebtoken');
const db = require('../config/database');
const ApiError = require('../utils/ApiError');

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
const STATIC_OTP = process.env.STATIC_OTP || '3456';
const SUPER_ADMIN_PHONE = '9999999999';
const SUPER_ADMIN_OTP = '8888';

const authService = {
  /**
   * Request OTP - validates phone exists and "sends" OTP
   * In production, this would send via WhatsApp/SMS
   */
  async requestOtp(phone) {
    if (!/^\d{10}$/.test(phone)) {
      throw ApiError.badRequest('Phone must be exactly 10 digits');
    }

    // Super admin auto-provision: ensure user exists
    if (phone === SUPER_ADMIN_PHONE) {
      let sa = await db('users').where({ phone: SUPER_ADMIN_PHONE }).first();
      if (!sa) {
        await db('users').insert({
          phone: SUPER_ADMIN_PHONE,
          name: 'Super Admin',
          role: 'super_admin',
          status: 'active',
        });
      }
      return { message: 'OTP sent', phone };
    }

    const user = await db('users').where({ phone, status: 'active' }).first();
    if (!user) throw ApiError.notFound('No account found with this phone number');

    // Check org status
    if (user.organization_id) {
      const org = await db('organizations').where({ id: user.organization_id }).first();
      if (!org || org.status !== 'active') {
        throw ApiError.forbidden('Organization is inactive');
      }
    }

    // In production: send OTP via WhatsApp/SMS
    // For now: static OTP is used
    return { message: 'OTP sent', phone };
  },

  /**
   * Verify OTP and return JWT
   */
  async verifyOtp(phone, otp) {
    if (!/^\d{10}$/.test(phone)) {
      throw ApiError.badRequest('Phone must be exactly 10 digits');
    }

    // Super admin has its own OTP
    if (phone === SUPER_ADMIN_PHONE) {
      if (otp !== SUPER_ADMIN_OTP) {
        throw ApiError.unauthorized('Invalid OTP');
      }
    } else {
      // Static OTP check for normal users
      if (otp !== STATIC_OTP) {
        throw ApiError.unauthorized('Invalid OTP');
      }
    }

    const user = await db('users').where({ phone, status: 'active' }).first();
    if (!user) throw ApiError.unauthorized('Invalid credentials');

    // Check org status (skip for super_admin who has no org)
    if (user.organization_id) {
      const org = await db('organizations').where({ id: user.organization_id }).first();
      if (!org || org.status !== 'active') {
        throw ApiError.forbidden('Organization is inactive');
      }
    }

    const previousLogin = user.last_login_at;

    // Update last_login_at
    await db('users').where({ id: user.id }).update({ last_login_at: db.fn.now() });

    const token = jwt.sign(
      { userId: user.id, role: user.role, organizationId: user.organization_id },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    let orgInfo = null;
    if (user.organization_id) {
      const org = await db('organizations').where({ id: user.organization_id }).first();
      if (org) {
        orgInfo = { id: org.id, name: org.name, place: org.place, logoUrl: org.logo_url };
      }
    }

    return {
      token,
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        organizationId: user.organization_id,
        photoUrl: user.photo_url,
        lastLoginAt: previousLogin,
      },
      organization: orgInfo,
    };
  },

  async updateFcmToken(userId, fcmToken) {
    await db('users').where({ id: userId }).update({ fcm_token: fcmToken, updated_at: db.fn.now() });
  },
};

module.exports = authService;
