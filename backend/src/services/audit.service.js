const db = require('../config/database');

const auditService = {
  async log({ organizationId, actorId, action, entityType, entityId, details }) {
    await db('audit_logs').insert({
      organization_id: organizationId,
      actor_id: actorId,
      action,
      entity_type: entityType,
      entity_id: entityId,
      details: details ? JSON.stringify(details) : null,
    });
  },
};

module.exports = auditService;
