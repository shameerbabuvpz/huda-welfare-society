const jwt = require('jsonwebtoken');
const db = require('../config/database');
const ApiError = require('../utils/ApiError');

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
const STATIC_OTP = process.env.STATIC_OTP || '3456';
const SUPER_ADMIN_PHONE = '9999999999';
const SUPER_ADMIN_OTP = '6543';

const authService = {
  /**
   * Get available roles for a user (from user_roles, primary role, and member linkage)
   */
  async getAvailableRoles(userId) {
    const roles = new Set();

    // 1. Get user's primary role
    const user = await db('users').where({ id: userId }).first();
    if (user) {
      roles.add(user.role);

      // 2. Check if user has a linked member record (by phone or user_id)
      if (user.phone) {
        const phone = user.phone.trim();
        const memberByPhone = await db('members')
          .whereRaw("TRIM(phone) = ? AND status = 'active'", [phone])
          .first();
        if (memberByPhone) {
          roles.add('member');
          // Link the member to user if not already linked
          if (!memberByPhone.user_id) {
            await db('members').where({ id: memberByPhone.id }).update({ user_id: userId });
          }
        }
      }

      const memberByUserId = await db('members')
        .where({ user_id: userId, status: 'active' })
        .first();
      if (memberByUserId) {
        roles.add('member');
      }
    }

    // 3. Also check user_roles table for additional roles
    try {
      const userRoles = await db('user_roles')
        .where({ user_id: userId })
        .select('role')
        .distinct('role');
      userRoles.forEach(r => roles.add(r.role));
    } catch (err) {
      // user_roles table may not exist yet
    }

    return [...roles];
  },

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

    // For member-role users, ensure they have a linked member profile
    if (user.role === 'member') {
      const member = await db('members')
        .where(function() {
          this.where({ user_id: user.id }).orWhere({ phone, status: 'active' });
        })
        .where({ organization_id: user.organization_id })
        .first();
      if (!member) {
        throw ApiError.notFound('No member profile linked to this number. Contact your admin.');
      }
    }

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

    // Get available roles for this user
    const availableRoles = await this.getAvailableRoles(user.id);
    if (availableRoles.length === 0) {
      availableRoles.push(user.role); // Fallback to primary role
    }

    // Set current_role if not already set, or if it's not in available roles
    let currentRole = user.current_role || user.role;
    if (!availableRoles.includes(currentRole)) {
      currentRole = availableRoles[0];
    }

    try {
      await db('users').where({ id: user.id }).update({ 
        last_login_at: db.fn.now(),
        current_role: currentRole,
        updated_at: db.fn.now()
      });
    } catch (err) {
      // current_role column may not exist yet (migration pending)
      await db('users').where({ id: user.id }).update({ 
        last_login_at: db.fn.now(),
        updated_at: db.fn.now()
      });
    }

    const token = jwt.sign(
      { 
        userId: user.id, 
        role: currentRole, 
        organizationId: user.organization_id,
        availableRoles: availableRoles
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    let orgInfo = null;
    if (user.organization_id) {
      const org = await db('organizations').where({ id: user.organization_id }).first();
      if (org) {
        orgInfo = { id: org.id, name: org.name, place: org.place, logoUrl: org.logo_url, status: org.status };
      }
    }

    return {
      token,
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        role: currentRole,
        roles: availableRoles,
        organizationId: user.organization_id,
        photoUrl: user.photo_url,
        lastLoginAt: previousLogin,
      },
      organization: orgInfo,
    };
  },

  /**
   * Switch current role for a user
   */
  async switchRole(userId, newRole, organizationId) {
    const user = await db('users').where({ id: userId }).first();
    if (!user) throw ApiError.notFound('User not found');

    // Check if user has this role
    const availableRoles = await this.getAvailableRoles(userId);
    if (!availableRoles.includes(newRole)) {
      throw ApiError.forbidden('User does not have this role');
    }

    // Update current_role
    try {
      await db('users').where({ id: userId }).update({
        current_role: newRole,
        updated_at: db.fn.now()
      });
    } catch (err) {
      // current_role column may not exist yet
      await db('users').where({ id: userId }).update({
        updated_at: db.fn.now()
      });
    }

    // Return new JWT with updated role
    const token = jwt.sign(
      { 
        userId: user.id, 
        role: newRole, 
        organizationId: organizationId || user.organization_id,
        availableRoles: availableRoles
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    return {
      token,
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        role: newRole,
        roles: availableRoles,
        organizationId: user.organization_id,
        photoUrl: user.photo_url,
      },
    };
  },

  async updateFcmToken(userId, fcmToken) {
    await db('users').where({ id: userId }).update({ fcm_token: fcmToken, updated_at: db.fn.now() });
  },
};

module.exports = authService;
