const db = require('../config/database');

const reportService = {
  async memberSummary(orgId) {
    const active = await db('members').where({ organization_id: orgId, status: 'active' }).count('id as count').first();
    const inactive = await db('members').where({ organization_id: orgId, status: 'inactive' }).count('id as count').first();
    return { active: parseInt(active.count, 10), inactive: parseInt(inactive.count, 10) };
  },

  async assetSummary(orgId) {
    const rows = await db('assets')
      .where({ organization_id: orgId })
      .select('status')
      .count('id as count')
      .groupBy('status');
    const summary = { available: 0, issued: 0, retired: 0 };
    rows.forEach(r => { summary[r.status] = parseInt(r.count, 10); });

    const overdue = await db('asset_transactions')
      .where({ organization_id: orgId, status: 'issued' })
      .andWhere('due_date', '<', new Date())
      .count('id as count')
      .first();
    summary.overdue = parseInt(overdue.count, 10);

    return summary;
  },

  async kuriCollectionSummary(orgId, groupId) {
    const group = await db('kuri_groups').where({ id: groupId, organization_id: orgId }).first();
    if (!group) return null;

    const rows = await db('kuri_collections')
      .where({ organization_id: orgId, kuri_group_id: groupId })
      .select('month_number', 'status')
      .count('id as count')
      .sum('amount as total')
      .groupBy('month_number', 'status')
      .orderBy('month_number');

    const totalCollected = await db('kuri_collections')
      .where({ organization_id: orgId, kuri_group_id: groupId, status: 'paid' })
      .sum('amount as total')
      .first();

    const totalPaidOut = await db('kuri_payouts')
      .where({ organization_id: orgId, kuri_group_id: groupId })
      .sum('amount as total')
      .first();

    return {
      group: { id: group.id, name: group.name, code: group.code },
      monthly_breakdown: rows,
      total_collected: parseFloat(totalCollected.total || 0),
      total_paid_out: parseFloat(totalPaidOut.total || 0),
    };
  },

  async kuriPayoutHistory(orgId, groupId) {
    return db('kuri_payouts')
      .where({ 'kuri_payouts.organization_id': orgId, 'kuri_payouts.kuri_group_id': groupId })
      .join('members', 'kuri_payouts.member_id', 'members.id')
      .select('kuri_payouts.*', 'members.name as member_name')
      .orderBy('kuri_payouts.payout_date');
  },

  async notificationSummary(orgId) {
    const total = await db('notifications').where({ organization_id: orgId }).count('id as count').first();
    const delivery = await db('notification_logs')
      .where({ organization_id: orgId })
      .select('status')
      .count('id as count')
      .groupBy('status');

    const summary = { total_notifications: parseInt(total.count, 10), sent: 0, failed: 0, pending: 0 };
    delivery.forEach(r => { summary[r.status] = parseInt(r.count, 10); });
    return summary;
  },
};

module.exports = reportService;
