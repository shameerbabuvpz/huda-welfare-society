const db = require('../config/database');
const ApiError = require('../utils/ApiError');
const auditService = require('./audit.service');

let firebaseAdmin = null;
try {
  const admin = require('firebase-admin');
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const serviceAccount = require(process.env.FIREBASE_SERVICE_ACCOUNT);
    if (!admin.apps.length) {
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    }
    firebaseAdmin = admin;
  }
} catch (_e) {
  console.warn('Firebase not configured – push notifications disabled');
}

const notificationService = {
  async send(orgId, { title, body, audienceType, memberIds }, actorId) {
    // Create notification record
    const [notification] = await db('notifications').insert({
      organization_id: orgId,
      title,
      body,
      audience_type: audienceType || 'all',
      created_by: actorId,
    }).returning('*');

    // Determine targets — fetch the FCM token in the same query (LEFT JOIN users)
    // to avoid an N+1 lookup per member.
    let targetsQuery = db('members')
      .leftJoin('users', 'members.user_id', 'users.id')
      .where({ 'members.organization_id': orgId, 'members.status': 'active' })
      .select('members.id', 'members.user_id', 'users.fcm_token');

    if (audienceType === 'specific' && memberIds && memberIds.length) {
      targetsQuery = targetsQuery.whereIn('members.id', memberIds);
    }
    const targets = await targetsQuery;

    // Send and log
    const logs = [];
    for (const member of targets) {
      let status = 'pending';
      let error = null;
      let sentAt = null;

      if (firebaseAdmin && member.user_id) {
        if (member.fcm_token) {
          try {
            await firebaseAdmin.messaging().send({
              token: member.fcm_token,
              notification: { title, body },
            });
            status = 'sent';
            sentAt = new Date();
          } catch (e) {
            status = 'failed';
            error = e.message;
          }
        } else {
          status = 'failed';
          error = 'No FCM token';
        }
      } else {
        status = 'failed';
        error = 'Firebase not configured or no user account';
      }

      logs.push({
        notification_id: notification.id,
        organization_id: orgId,
        member_id: member.id,
        status,
        error,
        sent_at: sentAt,
      });
    }

    if (logs.length) {
      await db('notification_logs').insert(logs);
    }

    await auditService.log({
      organizationId: orgId,
      actorId,
      action: 'notification.send',
      entityType: 'notification',
      entityId: notification.id,
      details: { title, audienceType, targetCount: targets.length },
    });

    return { notification, deliveryCount: logs.filter(l => l.status === 'sent').length, totalTargets: targets.length };
  },

  async list(orgId, { page = 1, limit = 20 }) {
    const total = await db('notifications').where({ organization_id: orgId }).count('id as count').first();
    const p = Math.max(1, parseInt(page, 10));
    const l = Math.min(100, Math.max(1, parseInt(limit, 10)));
    const rows = await db('notifications')
      .where({ organization_id: orgId })
      .orderBy('id', 'desc')
      .limit(l)
      .offset((p - 1) * l);

    const { paginationMeta } = require('../utils/pagination');
    return { data: rows, pagination: paginationMeta(parseInt(total.count, 10), p, l) };
  },

  async getDeliveryLogs(orgId, notificationId) {
    return db('notification_logs')
      .where({ notification_id: notificationId, organization_id: orgId })
      .leftJoin('members', 'notification_logs.member_id', 'members.id')
      .select('notification_logs.*', 'members.name as member_name');
  },

  async memberNotifications(orgId, memberId, { page = 1, limit = 20 }) {
    const total = await db('notification_logs')
      .where({ organization_id: orgId, member_id: memberId })
      .count('id as count')
      .first();

    const p = Math.max(1, parseInt(page, 10));
    const l = Math.min(100, Math.max(1, parseInt(limit, 10)));
    const rows = await db('notification_logs')
      .where({ 'notification_logs.organization_id': orgId, 'notification_logs.member_id': memberId })
      .join('notifications', 'notification_logs.notification_id', 'notifications.id')
      .select(
        'notifications.id',
        'notifications.title',
        'notifications.body',
        'notifications.audience_type',
        'notifications.created_at',
        'notification_logs.sent_at',
        'notification_logs.status'
      )
      .orderBy('notification_logs.id', 'desc')
      .limit(l)
      .offset((p - 1) * l);

    const { paginationMeta } = require('../utils/pagination');
    return { data: rows, pagination: paginationMeta(parseInt(total.count, 10), p, l) };
  },

  async update(orgId, notificationId, { title, body }) {
    const allowed = {};
    if (title !== undefined) allowed.title = title;
    if (body !== undefined) allowed.body = body;
    if (!Object.keys(allowed).length) throw ApiError.badRequest('Nothing to update');

    const [notification] = await db('notifications')
      .where({ id: notificationId, organization_id: orgId })
      .update({ ...allowed, updated_at: db.fn.now() })
      .returning('*');
    if (!notification) throw ApiError.notFound('Notification not found');
    return notification;
  },

  async delete(orgId, notificationId) {
    const notification = await db('notifications').where({ id: notificationId, organization_id: orgId }).first();
    if (!notification) throw ApiError.notFound('Notification not found');

    await db('notification_logs').where({ notification_id: notificationId, organization_id: orgId }).del();
    await db('notifications').where({ id: notificationId, organization_id: orgId }).del();
    return { deleted: true };
  },
};

module.exports = notificationService;
