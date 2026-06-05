const db = require('../config/database');
const ApiError = require('../utils/ApiError');
const auditService = require('./audit.service');

function generateKaneevCode(prefix = 'KNV') {
  const rand = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `${prefix}-${rand}`;
}

const kaneevService = {
  // ── Get or auto-create the single kaneev group for the org ──
  async getOrCreateGroup(orgId, actorId) {
    let group = await db('kaneev_groups').where({ organization_id: orgId }).first();
    if (!group) {
      const code = generateKaneevCode();
      [group] = await db('kaneev_groups').insert({
        organization_id: orgId,
        name: 'കനീവ്',
        code,
        donation_amount: 100,
        status: 'active',
        created_by: actorId,
        updated_by: actorId,
      }).returning('*');

      await auditService.log({
        organizationId: orgId, actorId, action: 'kaneev_group.create',
        entityType: 'kaneev_group', entityId: group.id, details: { name: 'കനീവ്' },
      });
    }
    return group;
  },

  async getGroupDetail(orgId, groupId) {
    const group = await db('kaneev_groups').where({ id: groupId, organization_id: orgId }).first();
    if (!group) throw ApiError.notFound('Kaneev group not found');

    // Per-member total paid (sum of paid donations)
    const paidTotals = await db('kaneev_donations')
      .where({ kaneev_group_id: groupId, organization_id: orgId, status: 'paid' })
      .groupBy('member_id')
      .select('member_id')
      .sum('amount as total_paid');
    const paidMap = {};
    paidTotals.forEach((row) => { paidMap[row.member_id] = parseFloat(row.total_paid) || 0; });

    const members = await db('kaneev_members')
      .where({ 'kaneev_members.kaneev_group_id': groupId, 'kaneev_members.organization_id': orgId, 'kaneev_members.status': 'active' })
      .join('members', 'kaneev_members.member_id', 'members.id')
      .leftJoin('ayalkoottams', 'members.ayalkoottam_id', 'ayalkoottams.id')
      .select(
        'kaneev_members.*',
        'kaneev_members.created_at as joined_date',
        'members.name as member_name',
        'members.member_code',
        'ayalkoottams.name as ayalkoottam_name',
      );

    members.forEach((m) => { m.total_paid = paidMap[m.member_id] || 0; });

    const recipients = await db('kaneev_recipients')
      .where({ 'kaneev_recipients.kaneev_group_id': groupId, 'kaneev_recipients.organization_id': orgId })
      .join('members', 'kaneev_recipients.member_id', 'members.id')
      .select('kaneev_recipients.*', 'members.name as member_name')
      .orderBy('month_number', 'desc');

    const balanceLogs = await db('kaneev_balance_log')
      .where({ kaneev_group_id: groupId, organization_id: orgId })
      .orderBy('month_number');

    const currentBalance = balanceLogs.length > 0
      ? parseFloat(balanceLogs[balanceLogs.length - 1].cumulative_balance)
      : 0;

    return { ...group, members, recipients, balance_logs: balanceLogs, current_balance: currentBalance };
  },

  async updateGroup(orgId, groupId, data, actorId) {
    const allowed = {};
    if (data.name !== undefined) allowed.name = data.name;
    if (data.donation_amount !== undefined) allowed.donation_amount = data.donation_amount;
    if (data.status !== undefined) allowed.status = data.status;

    const [group] = await db('kaneev_groups')
      .where({ id: groupId, organization_id: orgId })
      .update({ ...allowed, updated_by: actorId, updated_at: db.fn.now() })
      .returning('*');
    if (!group) throw ApiError.notFound('Kaneev group not found');
    return group;
  },

  // ── Member enrollment (no limit) ──
  async addMember(orgId, groupId, memberId, actorId) {
    const group = await db('kaneev_groups').where({ id: groupId, organization_id: orgId }).first();
    if (!group) throw ApiError.notFound('Kaneev group not found');

    const member = await db('members').where({ id: memberId, organization_id: orgId }).first();
    if (!member) throw ApiError.notFound('Member not found');

    const existing = await db('kaneev_members').where({ kaneev_group_id: groupId, member_id: memberId }).first();
    if (existing) {
      if (existing.status === 'withdrawn') {
        const [km] = await db('kaneev_members')
          .where({ id: existing.id })
          .update({ status: 'active', updated_at: db.fn.now() })
          .returning('*');
        return km;
      }
      throw ApiError.conflict('Member already enrolled');
    }

    const currentCount = await db('kaneev_members')
      .where({ kaneev_group_id: groupId, status: 'active' })
      .count('id as count').first();
    const slotNumber = parseInt(currentCount.count, 10) + 1;

    const [km] = await db('kaneev_members').insert({
      organization_id: orgId,
      kaneev_group_id: groupId,
      member_id: memberId,
      slot_number: slotNumber,
      status: 'active',
    }).returning('*');

    return km;
  },

  async removeMember(orgId, groupId, memberId) {
    const existing = await db('kaneev_members')
      .where({ kaneev_group_id: groupId, member_id: memberId, organization_id: orgId })
      .first();
    if (!existing) throw ApiError.notFound('Member not found in this group');

    // If the member has any paid donations, they cannot be deleted —
    // only deactivated, so their payment history is preserved.
    const paid = await db('kaneev_donations')
      .where({ kaneev_group_id: groupId, member_id: memberId, status: 'paid' })
      .first();
    if (paid) {
      throw ApiError.conflict(
        'This member has already made payments and cannot be deleted. Deactivate the member instead.',
      );
    }

    // No payments → safe to hard delete the enrollment.
    await db('kaneev_members')
      .where({ id: existing.id })
      .del();

    return { id: existing.id, member_id: memberId, deleted: true };
  },

  // ── Activate / deactivate a member (keeps payment history) ──
  async setMemberStatus(orgId, groupId, memberId, status) {
    if (!['active', 'withdrawn'].includes(status)) {
      throw ApiError.badRequest('Invalid status. Use "active" or "withdrawn".');
    }
    const [km] = await db('kaneev_members')
      .where({ kaneev_group_id: groupId, member_id: memberId, organization_id: orgId })
      .update({ status, updated_at: db.fn.now() })
      .returning('*');
    if (!km) throw ApiError.notFound('Member not found in this group');
    return km;
  },

  // ── Donations (no month limit) ──
  async recordDonation(orgId, groupId, { memberId, monthNumber, amount, paidDate }, actorId) {
    const group = await db('kaneev_groups').where({ id: groupId, organization_id: orgId }).first();
    if (!group) throw ApiError.notFound('Kaneev group not found');

    const existing = await db('kaneev_donations')
      .where({ kaneev_group_id: groupId, member_id: memberId, month_number: monthNumber, status: 'paid' })
      .first();
    if (existing) throw ApiError.conflict('Donation already recorded for this member this month');

    const [donation] = await db('kaneev_donations').insert({
      organization_id: orgId,
      kaneev_group_id: groupId,
      member_id: memberId,
      month_number: monthNumber,
      amount: amount || group.donation_amount,
      paid_date: paidDate || new Date(),
      status: 'paid',
      created_by: actorId,
    }).returning('*');

    await kaneevService._recalcMonthBalance(orgId, groupId, monthNumber, actorId);

    return donation;
  },

  async getDonations(orgId, groupId, { monthNumber, memberId } = {}) {
    let query = db('kaneev_donations')
      .where({ 'kaneev_donations.organization_id': orgId, 'kaneev_donations.kaneev_group_id': groupId })
      .join('members', 'kaneev_donations.member_id', 'members.id')
      .leftJoin('ayalkoottams', 'members.ayalkoottam_id', 'ayalkoottams.id')
      .select('kaneev_donations.*', 'members.name as member_name', 'ayalkoottams.name as ayalkoottam_name');

    if (monthNumber) query = query.andWhere({ 'kaneev_donations.month_number': monthNumber });
    if (memberId) query = query.andWhere({ 'kaneev_donations.member_id': memberId });

    return query.orderBy('kaneev_donations.month_number').orderBy('members.name');
  },

  // ── Recipient selection ──
  async selectRecipient(orgId, groupId, { memberId, monthNumber, amount }, actorId) {
    const group = await db('kaneev_groups').where({ id: groupId, organization_id: orgId }).first();
    if (!group) throw ApiError.notFound('Kaneev group not found');

    const alreadyReceived = await db('kaneev_recipients')
      .where({ kaneev_group_id: groupId, member_id: memberId })
      .first();
    if (alreadyReceived) throw ApiError.conflict('Member has already received kaneev');

    const enrolled = await db('kaneev_members')
      .where({ kaneev_group_id: groupId, member_id: memberId, status: 'active' })
      .first();
    if (!enrolled) throw ApiError.badRequest('Member is not enrolled');

    let totalAmount = amount;
    if (totalAmount == null || totalAmount === undefined) {
      const totalCollected = await db('kaneev_donations')
        .where({ kaneev_group_id: groupId, month_number: monthNumber, status: 'paid' })
        .sum('amount as total')
        .first();
      totalAmount = totalCollected?.total || 0;
    }

    const [recipient] = await db('kaneev_recipients').insert({
      organization_id: orgId,
      kaneev_group_id: groupId,
      member_id: memberId,
      month_number: monthNumber,
      total_amount: totalAmount,
      received_date: new Date(),
    }).returning('*');

    await kaneevService._recalcMonthBalance(orgId, groupId, monthNumber, actorId);

    await auditService.log({
      organizationId: orgId, actorId, action: 'kaneev.recipient_selected',
      entityType: 'kaneev_recipient', entityId: recipient.id,
      details: { groupId, memberId, monthNumber },
    });

    return recipient;
  },

  async recipientHistory(orgId, groupId) {
    return db('kaneev_recipients')
      .where({ 'kaneev_recipients.kaneev_group_id': groupId, 'kaneev_recipients.organization_id': orgId })
      .join('members', 'kaneev_recipients.member_id', 'members.id')
      .select('kaneev_recipients.*', 'members.name as member_name')
      .orderBy('month_number', 'desc');
  },

  // ── Member self-service ──
  async myKaneev(orgId, memberId) {
    const group = await db('kaneev_groups').where({ organization_id: orgId }).first();
    if (!group) return null;

    const enrollment = await db('kaneev_members')
      .where({ kaneev_group_id: group.id, member_id: memberId, status: 'active' })
      .first();
    if (!enrollment) return null;

    const received = await db('kaneev_recipients')
      .where({ kaneev_group_id: group.id, member_id: memberId })
      .first();

    return {
      ...group,
      slot_number: enrollment.slot_number,
      has_received: !!received,
      received_month: received ? received.month_number : null,
    };
  },

  // ── Balance tracking ──
  async _recalcMonthBalance(orgId, groupId, monthNumber, actorId) {
    const collected = await db('kaneev_donations')
      .where({ kaneev_group_id: groupId, month_number: monthNumber, status: 'paid' })
      .sum('amount as total')
      .first();
    const totalCollected = parseFloat(collected?.total || 0);

    const distributed = await db('kaneev_recipients')
      .where({ kaneev_group_id: groupId, month_number: monthNumber })
      .sum('total_amount as total')
      .first();
    const totalDistributed = parseFloat(distributed?.total || 0);

    const monthBalance = totalCollected - totalDistributed;

    const prevBalance = await db('kaneev_balance_log')
      .where({ kaneev_group_id: groupId })
      .andWhere('month_number', '<', monthNumber)
      .orderBy('month_number', 'desc')
      .first();
    const prevCumulative = parseFloat(prevBalance?.cumulative_balance || 0);
    const cumulativeBalance = prevCumulative + monthBalance;

    const existing = await db('kaneev_balance_log')
      .where({ kaneev_group_id: groupId, month_number: monthNumber })
      .first();

    if (existing) {
      await db('kaneev_balance_log')
        .where({ id: existing.id })
        .update({
          total_collected: totalCollected,
          total_distributed: totalDistributed,
          month_balance: monthBalance,
          cumulative_balance: cumulativeBalance,
          updated_at: db.fn.now(),
        });
    } else {
      await db('kaneev_balance_log').insert({
        organization_id: orgId,
        kaneev_group_id: groupId,
        month_number: monthNumber,
        total_collected: totalCollected,
        total_distributed: totalDistributed,
        month_balance: monthBalance,
        cumulative_balance: cumulativeBalance,
        created_by: actorId,
      });
    }

    const laterMonths = await db('kaneev_balance_log')
      .where({ kaneev_group_id: groupId })
      .andWhere('month_number', '>', monthNumber)
      .orderBy('month_number');

    let runningCumulative = cumulativeBalance;
    for (const row of laterMonths) {
      runningCumulative += parseFloat(row.month_balance);
      await db('kaneev_balance_log')
        .where({ id: row.id })
        .update({ cumulative_balance: runningCumulative, updated_at: db.fn.now() });
    }
  },

  async recalcMonthBalance(orgId, groupId, monthNumber, actorId) {
    return this._recalcMonthBalance(orgId, groupId, monthNumber, actorId);
  },

  async getBalanceHistory(orgId, groupId) {
    const logs = await db('kaneev_balance_log')
      .where({ kaneev_group_id: groupId, organization_id: orgId })
      .orderBy('month_number');

    const currentBalance = logs.length > 0
      ? parseFloat(logs[logs.length - 1].cumulative_balance)
      : 0;

    return { logs, currentBalance };
  },
};

module.exports = kaneevService;
