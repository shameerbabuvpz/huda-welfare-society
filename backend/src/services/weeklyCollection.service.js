const db = require('../config/database');
const ApiError = require('../utils/ApiError');
const { paginationMeta } = require('../utils/pagination');
const auditService = require('./audit.service');

// Net cash movement for a week's collection.
// Money in:  deposit + loan_repayment
// Money out: withdrawal + loan
const computeNet = ({ deposit = 0, withdrawal = 0, loan = 0, loan_repayment = 0 }) =>
  Number(deposit) - Number(withdrawal) - Number(loan) + Number(loan_repayment);

const toDateStr = (value) => {
  if (!value) return null;
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  return String(value).slice(0, 10);
};

const num = (v) => parseFloat(v) || 0;

const weeklyCollectionService = {
  // ─── Create / Update a week's entry for one ayalkoottam ───────
  async upsert(orgId, data, actorId) {
    const ayalkoottam = await db('ayalkoottams')
      .where({ id: data.ayalkoottam_id, organization_id: orgId })
      .first();
    if (!ayalkoottam) throw ApiError.notFound('Ayalkoottam not found');

    const week = toDateStr(data.week_start_date);
    const payload = {
      deposit: num(data.deposit),
      withdrawal: num(data.withdrawal),
      loan: num(data.loan),
      loan_repayment: num(data.loan_repayment),
      note: data.note || null,
    };
    payload.net_total = computeNet(payload);

    const existing = await db('weekly_collections')
      .where({ organization_id: orgId, ayalkoottam_id: data.ayalkoottam_id, week_start_date: week })
      .first();

    let row;
    if (existing) {
      [row] = await db('weekly_collections')
        .where({ id: existing.id })
        .update({ ...payload, updated_by: actorId, updated_at: db.fn.now() })
        .returning('*');
      await auditService.log({
        organizationId: orgId, actorId, action: 'weekly_collection.update',
        entityType: 'weekly_collection', entityId: row.id,
        details: { week_start_date: week, net_total: row.net_total },
      });
    } else {
      [row] = await db('weekly_collections')
        .insert({
          organization_id: orgId,
          ayalkoottam_id: data.ayalkoottam_id,
          week_start_date: week,
          ...payload,
          created_by: actorId,
          updated_by: actorId,
        })
        .returning('*');
      await auditService.log({
        organizationId: orgId, actorId, action: 'weekly_collection.create',
        entityType: 'weekly_collection', entityId: row.id,
        details: { week_start_date: week, net_total: row.net_total },
      });
    }

    return row;
  },

  // ─── List raw entries ─────────────────────────────────────────
  async list(orgId, { page = 1, limit = 20, ayalkoottam_id, week_start_date, from_date, to_date } = {}) {
    let query = db('weekly_collections as wc')
      .join('ayalkoottams as ak', 'wc.ayalkoottam_id', 'ak.id')
      .where({ 'wc.organization_id': orgId })
      .select('wc.*', 'ak.name as ayalkoottam_name', 'ak.place as ayalkoottam_place');

    if (ayalkoottam_id) query = query.andWhere({ 'wc.ayalkoottam_id': ayalkoottam_id });
    if (week_start_date) query = query.andWhere({ 'wc.week_start_date': toDateStr(week_start_date) });
    if (from_date) query = query.andWhere('wc.week_start_date', '>=', toDateStr(from_date));
    if (to_date) query = query.andWhere('wc.week_start_date', '<=', toDateStr(to_date));

    const total = await query.clone().clearSelect().count('wc.id as count').first();
    const p = Math.max(1, parseInt(page, 10));
    const l = Math.min(100, Math.max(1, parseInt(limit, 10)));
    const rows = await query
      .orderBy('wc.week_start_date', 'desc')
      .orderBy('ak.name', 'asc')
      .limit(l)
      .offset((p - 1) * l);

    return {
      data: rows.map((r) => ({ ...r, week_start_date: toDateStr(r.week_start_date) })),
      pagination: paginationMeta(parseInt(total.count, 10), p, l),
    };
  },

  async getById(orgId, id) {
    const row = await db('weekly_collections as wc')
      .join('ayalkoottams as ak', 'wc.ayalkoottam_id', 'ak.id')
      .where({ 'wc.id': id, 'wc.organization_id': orgId })
      .select('wc.*', 'ak.name as ayalkoottam_name', 'ak.place as ayalkoottam_place')
      .first();
    if (!row) throw ApiError.notFound('Entry not found');
    row.week_start_date = toDateStr(row.week_start_date);
    return row;
  },

  async update(orgId, id, data, actorId) {
    const existing = await db('weekly_collections').where({ id, organization_id: orgId }).first();
    if (!existing) throw ApiError.notFound('Entry not found');

    const merged = {
      deposit: data.deposit !== undefined ? num(data.deposit) : num(existing.deposit),
      withdrawal: data.withdrawal !== undefined ? num(data.withdrawal) : num(existing.withdrawal),
      loan: data.loan !== undefined ? num(data.loan) : num(existing.loan),
      loan_repayment: data.loan_repayment !== undefined ? num(data.loan_repayment) : num(existing.loan_repayment),
    };
    const updates = {
      ...merged,
      net_total: computeNet(merged),
      note: data.note !== undefined ? (data.note || null) : existing.note,
      updated_by: actorId,
      updated_at: db.fn.now(),
    };
    if (data.week_start_date) updates.week_start_date = toDateStr(data.week_start_date);

    const [row] = await db('weekly_collections').where({ id }).update(updates).returning('*');

    await auditService.log({
      organizationId: orgId, actorId, action: 'weekly_collection.update',
      entityType: 'weekly_collection', entityId: id, details: { net_total: row.net_total },
    });

    row.week_start_date = toDateStr(row.week_start_date);
    return row;
  },

  async remove(orgId, id, actorId) {
    const existing = await db('weekly_collections').where({ id, organization_id: orgId }).first();
    if (!existing) throw ApiError.notFound('Entry not found');
    await db('weekly_collections').where({ id }).del();

    await auditService.log({
      organizationId: orgId, actorId, action: 'weekly_collection.delete',
      entityType: 'weekly_collection', entityId: id,
    });

    return { message: 'Entry deleted' };
  },

  // ─── Consolidated report ──────────────────────────────────────
  // group_by: 'week' (default) | 'month'
  // Returns periods (each with per-ayalkoottam breakdown), a per-ayalkoottam
  // summary across the whole range, and grand totals.
  async getConsolidated(orgId, { from_date, to_date, group_by = 'week', ayalkoottam_id } = {}) {
    let query = db('weekly_collections as wc')
      .join('ayalkoottams as ak', 'wc.ayalkoottam_id', 'ak.id')
      .where({ 'wc.organization_id': orgId })
      .select(
        'wc.id', 'wc.ayalkoottam_id', 'wc.week_start_date',
        'wc.deposit', 'wc.withdrawal', 'wc.loan', 'wc.loan_repayment', 'wc.net_total',
        'ak.name as ayalkoottam_name', 'ak.place as ayalkoottam_place'
      );

    if (from_date) query = query.andWhere('wc.week_start_date', '>=', toDateStr(from_date));
    if (to_date) query = query.andWhere('wc.week_start_date', '<=', toDateStr(to_date));
    if (ayalkoottam_id) query = query.andWhere({ 'wc.ayalkoottam_id': ayalkoottam_id });

    const rows = await query.orderBy('wc.week_start_date', 'asc').orderBy('ak.name', 'asc');

    const periodMap = new Map();
    const akMap = new Map();
    const grand = { deposit: 0, withdrawal: 0, loan: 0, loan_repayment: 0, net_total: 0, entry_count: 0 };

    const emptyTotals = () => ({ deposit: 0, withdrawal: 0, loan: 0, loan_repayment: 0, net_total: 0, entry_count: 0 });
    const addInto = (target, r) => {
      target.deposit += num(r.deposit);
      target.withdrawal += num(r.withdrawal);
      target.loan += num(r.loan);
      target.loan_repayment += num(r.loan_repayment);
      target.net_total += num(r.net_total);
      target.entry_count += 1;
    };

    for (const r of rows) {
      const weekStr = toDateStr(r.week_start_date);
      let periodKey, periodStart, periodEnd;
      if (group_by === 'month') {
        periodKey = weekStr.slice(0, 7); // YYYY-MM
        periodStart = `${periodKey}-01`;
        const [y, m] = periodKey.split('-').map(Number);
        periodEnd = toDateStr(new Date(Date.UTC(y, m, 0))); // last day of month
      } else {
        periodKey = weekStr;
        periodStart = weekStr;
        const d = new Date(`${weekStr}T00:00:00Z`);
        d.setUTCDate(d.getUTCDate() + 6);
        periodEnd = toDateStr(d);
      }

      if (!periodMap.has(periodKey)) {
        periodMap.set(periodKey, {
          period_key: periodKey,
          period_start: periodStart,
          period_end: periodEnd,
          totals: emptyTotals(),
          ayalkoottams: new Map(),
        });
      }
      const period = periodMap.get(periodKey);
      addInto(period.totals, r);

      if (!period.ayalkoottams.has(r.ayalkoottam_id)) {
        period.ayalkoottams.set(r.ayalkoottam_id, {
          ayalkoottam_id: r.ayalkoottam_id,
          ayalkoottam_name: r.ayalkoottam_name,
          ayalkoottam_place: r.ayalkoottam_place,
          ...emptyTotals(),
        });
      }
      addInto(period.ayalkoottams.get(r.ayalkoottam_id), r);

      if (!akMap.has(r.ayalkoottam_id)) {
        akMap.set(r.ayalkoottam_id, {
          ayalkoottam_id: r.ayalkoottam_id,
          ayalkoottam_name: r.ayalkoottam_name,
          ayalkoottam_place: r.ayalkoottam_place,
          ...emptyTotals(),
        });
      }
      addInto(akMap.get(r.ayalkoottam_id), r);

      addInto(grand, r);
    }

    const round2 = (o) => {
      Object.keys(o).forEach((k) => {
        if (typeof o[k] === 'number' && k !== 'entry_count') o[k] = Math.round(o[k] * 100) / 100;
      });
      return o;
    };

    const periods = Array.from(periodMap.values())
      .sort((a, b) => (a.period_key < b.period_key ? 1 : -1))
      .map((p) => ({
        period_key: p.period_key,
        period_start: p.period_start,
        period_end: p.period_end,
        ...round2({ ...p.totals }),
        ayalkoottams: Array.from(p.ayalkoottams.values()).map(round2),
      }));

    const byAyalkoottam = Array.from(akMap.values())
      .map(round2)
      .sort((a, b) => a.ayalkoottam_name.localeCompare(b.ayalkoottam_name));

    return {
      group_by,
      from_date: from_date ? toDateStr(from_date) : null,
      to_date: to_date ? toDateStr(to_date) : null,
      periods,
      by_ayalkoottam: byAyalkoottam,
      totals: round2(grand),
    };
  },
};

module.exports = weeklyCollectionService;
