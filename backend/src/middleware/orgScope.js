const ApiError = require('../utils/ApiError');
const db = require('../config/database');

async function orgScope(req, _res, next) {
  try {
    // Super admins can pass orgId in header for cross-org access
    if (req.user.role === 'super_admin') {
      const headerOrg = req.headers['x-organization-id'];
      if (headerOrg) {
        const org = await db('organizations').where({ id: parseInt(headerOrg, 10), status: 'active' }).first();
        if (!org) throw ApiError.notFound('Organization not found');
        req.organizationId = org.id;
      }
      return next();
    }

    // Admin and member must belong to an active organization
    if (!req.user.organizationId) {
      throw ApiError.forbidden('User not assigned to an organization');
    }

    const org = await db('organizations').where({ id: req.user.organizationId, status: 'active' }).first();
    if (!org) throw ApiError.forbidden('Organization inactive or not found');

    req.organizationId = org.id;
    next();
  } catch (err) {
    next(err);
  }
}

module.exports = { orgScope };
