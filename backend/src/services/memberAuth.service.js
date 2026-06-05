const jwt = require('jsonwebtoken');
const knex = require('../config/database');
const ApiError = require('../utils/ApiError');

const memberAuthService = {
  /**
   * Member login with code
   * @param {number} organizationId - Organization ID
   * @param {number} memberId - Member ID
   * @param {string} code - Login code (4-digit)
   * @returns {Object} { token, member, mustChangeCode }
   */
  async loginWithCode(organizationId, memberId, code) {
    // Validate inputs
    if (!code || code.length !== 4) {
      throw new ApiError(400, 'Invalid code format. Code must be 4 digits.');
    }

    // Get member
    const member = await knex('members')
      .where({
        id: memberId,
        organization_id: organizationId,
        status: 'active',
      })
      .first();

    if (!member) {
      throw new ApiError(404, 'Member not found.');
    }

    // Verify code
    if (member.login_code !== code) {
      throw new ApiError(401, 'Invalid code.');
    }

    // Generate JWT token
    const token = jwt.sign(
      {
        memberId: member.id,
        organizationId: member.organization_id,
        type: 'member',
      },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' },
    );

    // Check if member must change their code
    const mustChangeCode = !member.code_changed;

    return {
      token,
      member: {
        id: member.id,
        name: member.name,
        phone: member.phone,
        memberCode: member.member_code,
      },
      mustChangeCode, // true if still using default code (6789)
    };
  },

  /**
   * Member login with phone number and 4-digit code
   * Provisions/links a `users` row (role 'member') so the member dashboard,
   * which is protected by the standard user `authenticate` middleware, works.
   * @param {number} organizationId - Organization ID
   * @param {string} phone - Member phone number
   * @param {string} code - Login code (4-digit)
   * @returns {Object} { token, member, mustChangeCode }
   */
  async loginWithPhoneCode(organizationId, phone, code) {
    // Validate inputs
    if (!code || code.length !== 4) {
      throw new ApiError(400, 'Invalid code format. Code must be 4 digits.');
    }

    // Normalize phone to last 10 digits for matching
    const normalizedPhone = String(phone).replace(/\D/g, '').slice(-10);
    if (normalizedPhone.length < 10) {
      throw new ApiError(400, 'Invalid phone number.');
    }

    // Find active member by normalized phone within the organization
    const member = await knex('members')
      .where({
        organization_id: organizationId,
        status: 'active',
      })
      .whereRaw("right(regexp_replace(phone, '\\D', '', 'g'), 10) = ?", [normalizedPhone])
      .first();

    if (!member) {
      throw new ApiError(404, 'Member not found with this phone number.');
    }

    // Verify code
    if (member.login_code !== code) {
      throw new ApiError(401, 'Invalid code.');
    }

    // Ensure a linked `users` row exists for this member (role 'member').
    // The member dashboard endpoints are protected by the standard user
    // authenticate middleware, so members need a user-shaped JWT.
    let user = null;
    if (member.user_id) {
      user = await knex('users').where({ id: member.user_id }).first();
    }
    if (!user) {
      user = await knex('users')
        .where({ organization_id: organizationId })
        .whereRaw("right(regexp_replace(phone, '\\D', '', 'g'), 10) = ?", [normalizedPhone])
        .first();
    }
    if (!user) {
      const [created] = await knex('users')
        .insert({
          organization_id: organizationId,
          phone: normalizedPhone,
          name: member.name,
          role: 'member',
          status: 'active',
        })
        .returning('*');
      user = created;
    }

    // Reactivate the user if it was previously deactivated
    if (user.status !== 'active') {
      await knex('users').where({ id: user.id }).update({ status: 'active', updated_at: knex.fn.now() });
    }

    // Link member to user for future lookups
    if (member.user_id !== user.id) {
      await knex('members').where({ id: member.id }).update({ user_id: user.id, updated_at: knex.fn.now() });
    }

    // Generate a user-shaped JWT token (compatible with authenticate middleware)
    const token = jwt.sign(
      {
        userId: user.id,
        role: 'member',
        organizationId,
        availableRoles: ['member'],
      },
      process.env.JWT_SECRET || 'dev-secret',
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' },
    );

    // Check if member must change their code
    const mustChangeCode = !member.code_changed;

    return {
      token,
      member: {
        id: member.id,
        name: member.name,
        phone: member.phone,
        memberCode: member.member_code,
      },
      mustChangeCode, // true if still using default code (6789)
    };
  },

  /**
   * Check whether a phone number belongs to an active member and/or an
   * admin user. Used by the main login screen to route members to the
   * PIN login flow and admins to the OTP flow. No auth required.
   * @param {string} phone - Phone number (any format)
   * @returns {Object} { isMember, isAdmin, name }
   */
  async checkPhone(phone) {
    const normalizedPhone = String(phone).replace(/\D/g, '').slice(-10);
    if (normalizedPhone.length < 10) {
      return { isMember: false, isAdmin: false, name: null };
    }

    // Super admin is provisioned lazily at OTP time; treat as admin-only.
    if (normalizedPhone === '9999999999') {
      return { isMember: false, isAdmin: true, organizationId: null, name: 'Super Admin' };
    }

    const member = await knex('members')
      .where({ status: 'active' })
      .whereRaw("right(regexp_replace(phone, '\\D', '', 'g'), 10) = ?", [normalizedPhone])
      .first();

    const adminUser = await knex('users')
      .where({ status: 'active' })
      .whereNot({ role: 'member' })
      .whereRaw("right(regexp_replace(coalesce(phone, ''), '\\D', '', 'g'), 10) = ?", [normalizedPhone])
      .first();

    return {
      isMember: !!member,
      isAdmin: !!adminUser,
      organizationId: member ? member.organization_id : (adminUser ? adminUser.organization_id : null),
      name: member ? member.name : (adminUser ? adminUser.name : null),
    };
  },

  /**
   * Change member login code
   * @param {number} organizationId - Organization ID
   * @param {number} memberId - Member ID
   * @param {string} currentCode - Current code (must match for verification)
   * @param {string} newCode - New 4-digit code
   * @returns {Object} Updated member data
   */
  async changeCode(organizationId, memberId, currentCode, newCode) {
    // Validate inputs
    if (!currentCode || currentCode.length !== 4) {
      throw new ApiError(400, 'Invalid current code format.');
    }
    if (!newCode || newCode.length !== 4) {
      throw new ApiError(400, 'Invalid new code format. Code must be 4 digits.');
    }
    if (!/^\d{4}$/.test(newCode)) {
      throw new ApiError(400, 'Code must contain only digits.');
    }
    if (currentCode === newCode) {
      throw new ApiError(400, 'New code must be different from current code.');
    }

    // Get member
    const member = await knex('members')
      .where({
        id: memberId,
        organization_id: organizationId,
        status: 'active',
      })
      .first();

    if (!member) {
      throw new ApiError(404, 'Member not found.');
    }

    // Verify current code
    if (member.login_code !== currentCode) {
      throw new ApiError(401, 'Current code is incorrect.');
    }

    // Update code
    await knex('members')
      .where({ id: memberId })
      .update({
        login_code: newCode,
        code_changed: true,
        updated_at: knex.fn.now(),
      });

    return {
      id: member.id,
      name: member.name,
      phone: member.phone,
      memberCode: member.member_code,
      message: 'Code changed successfully',
    };
  },

  /**
   * Reset member code to default (6789) - Admin function
   * @param {number} organizationId - Organization ID
   * @param {number} memberId - Member ID
   * @returns {Object} Updated member data
   */
  async resetCodeToDefault(organizationId, memberId) {
    // Get member
    const member = await knex('members')
      .where({
        id: memberId,
        organization_id: organizationId,
        status: 'active',
      })
      .first();

    if (!member) {
      throw new ApiError(404, 'Member not found.');
    }

    // Reset to default 6789
    await knex('members')
      .where({ id: memberId })
      .update({
        login_code: '6789',
        code_changed: false, // Mark as using default again
        updated_at: knex.fn.now(),
      });

    return {
      id: member.id,
      name: member.name,
      memberCode: member.member_code,
      loginCode: '6789',
      message: 'Code reset to default 6789',
    };
  },

  /**
   * Get member's current code status (admin view)
   * @param {number} organizationId - Organization ID
   * @param {number} memberId - Member ID
   * @returns {Object} Member code info
   */
  async getMemberCodeStatus(organizationId, memberId) {
    const member = await knex('members')
      .where({
        id: memberId,
        organization_id: organizationId,
      })
      .select('id', 'name', 'member_code', 'login_code', 'code_changed')
      .first();

    if (!member) {
      throw new ApiError(404, 'Member not found.');
    }

    return {
      memberId: member.id,
      memberName: member.name,
      memberCode: member.member_code,
      isUsingDefaultCode: !member.code_changed,
      lastUpdated: member.updated_at,
    };
  },

  /**
   * Get member profile after login
   * @param {number} organizationId - Organization ID
   * @param {number} memberId - Member ID
   * @returns {Object} Member profile
   */
  async getProfile(organizationId, memberId) {
    const member = await knex('members')
      .where({
        id: memberId,
        organization_id: organizationId,
        status: 'active',
      })
      .select(
        'id',
        'name',
        'phone',
        'email',
        'member_code',
        'address',
        'join_date',
        'status',
        'created_at',
      )
      .first();

    if (!member) {
      throw new ApiError('Member not found.', 404);
    }

    return member;
  },

  /**
   * Request OTP for member phone login
   * @param {string} phone - Phone number (10 digits)
   * @returns {Object} { message, phone }
   */
  async requestPhoneOtp(phone) {
    if (!/^\d{10}$/.test(phone)) {
      throw new ApiError(400, 'Phone must be exactly 10 digits');
    }

    // Check if a member exists with this phone
    const member = await knex('members')
      .where({ phone, status: 'active' })
      .first();

    if (!member) {
      throw new ApiError(404, 'No member found with this phone number');
    }

    // In production: send OTP via WhatsApp/SMS
    // For now: static OTP is used
    return { message: 'OTP sent', phone };
  },

  /**
   * Login member with phone + OTP
   * @param {string} phone - Phone number (10 digits)
   * @param {string} otp - OTP code
   * @returns {Object} { token, member, mustChangeCode }
   */
  async loginWithPhone(phone, otp) {
    if (!/^\d{10}$/.test(phone)) {
      throw new ApiError(400, 'Phone must be exactly 10 digits');
    }

    // Verify OTP (static for now)
    const STATIC_OTP = process.env.STATIC_OTP || '3456';
    if (otp !== STATIC_OTP) {
      throw new ApiError(401, 'Invalid OTP');
    }

    // Find member by phone
    const member = await knex('members')
      .where({ phone, status: 'active' })
      .first();

    if (!member) {
      throw new ApiError(404, 'No member found with this phone number');
    }

    // Generate JWT token (same format as loginWithCode)
    const token = jwt.sign(
      {
        memberId: member.id,
        organizationId: member.organization_id,
        type: 'member',
      },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' },
    );

    // Check if member must change their code
    const mustChangeCode = !member.code_changed;

    return {
      token,
      member: {
        id: member.id,
        name: member.name,
        phone: member.phone,
        memberCode: member.member_code,
      },
      mustChangeCode,
    };
  },
};

module.exports = memberAuthService;
