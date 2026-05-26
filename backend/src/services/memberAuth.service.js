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
      throw new AppError('Invalid code format. Code must be 4 digits.', 400);
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
      throw new AppError('Member not found.', 404);
    }

    // Verify code
    if (member.login_code !== code) {
      throw new AppError('Invalid code.', 401);
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
      throw new AppError('Invalid current code format.', 400);
    }
    if (!newCode || newCode.length !== 4) {
      throw new AppError('Invalid new code format. Code must be 4 digits.', 400);
    }
    if (!/^\d{4}$/.test(newCode)) {
      throw new AppError('Code must contain only digits.', 400);
    }
    if (currentCode === newCode) {
      throw new AppError('New code must be different from current code.', 400);
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
      throw new AppError('Member not found.', 404);
    }

    // Verify current code
    if (member.login_code !== currentCode) {
      throw new AppError('Current code is incorrect.', 401);
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
      throw new AppError('Member not found.', 404);
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
      throw new AppError('Member not found.', 404);
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
      throw new AppError('Member not found.', 404);
    }

    return member;
  },
};

module.exports = memberAuthService;
