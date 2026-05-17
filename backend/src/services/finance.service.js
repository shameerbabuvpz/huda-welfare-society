const db = require('../config/database');
const ApiError = require('../utils/ApiError');
const { paginationMeta } = require('../utils/pagination');
const auditService = require('./audit.service');

const financeService = {
  // ─── Categories ───────────────────────────────────────────────
  async createCategory(orgId, data, actorId) {
    const existing = await db('finance_categories')
      .where({ organization_id: orgId, name: data.name, type: data.type })
      .first();
    if (existing) throw new ApiError(409, 'Category already exists');

    const [category] = await db('finance_categories').insert({
      organization_id: orgId,
      name: data.name,
      type: data.type,
      created_by: actorId,
    }).returning('*');

    await auditService.log({
      organizationId: orgId, actorId, action: 'finance_category.create',
      entityType: 'finance_category', entityId: category.id, details: { name: data.name, type: data.type },
    });

    return category;
  },

  async listCategories(orgId, { type } = {}) {
    let query = db('finance_categories').where({ organization_id: orgId });
    if (type) query = query.andWhere({ type });
    return await query.orderBy('name', 'asc');
  },

  async deleteCategory(orgId, categoryId) {
    const usageCount = await db('finance_transactions')
      .where({ organization_id: orgId, category_id: categoryId })
      .count('id as count')
      .first();
    if (parseInt(usageCount.count, 10) > 0) {
      throw new ApiError(400, 'Cannot delete category with existing transactions');
    }
    const deleted = await db('finance_categories')
      .where({ id: categoryId, organization_id: orgId })
      .del();
    if (!deleted) throw new ApiError(404, 'Category not found');
    return { message: 'Category deleted' };
  },

  // ─── Transactions ─────────────────────────────────────────────
  async createTransaction(orgId, data, actorId) {
    // Verify category belongs to this org and matches type
    const category = await db('finance_categories')
      .where({ id: data.category_id, organization_id: orgId })
      .first();
    if (!category) throw new ApiError(404, 'Category not found');
    if (category.type !== data.type) throw new ApiError(400, 'Category type mismatch');

    const [txn] = await db('finance_transactions').insert({
      organization_id: orgId,
      category_id: data.category_id,
      type: data.type,
      amount: data.amount,
      date: data.date,
      description: data.description || null,
      created_by: actorId,
    }).returning('*');

    await auditService.log({
      organizationId: orgId, actorId, action: `finance.${data.type}.create`,
      entityType: 'finance_transaction', entityId: txn.id, details: { amount: data.amount, date: data.date },
    });

    return txn;
  },

  async listTransactions(orgId, { type, category_id, page = 1, limit = 20, from_date, to_date }) {
    let query = db('finance_transactions as ft')
      .join('finance_categories as fc', 'ft.category_id', 'fc.id')
      .where({ 'ft.organization_id': orgId })
      .select('ft.*', 'fc.name as category_name');

    if (type) query = query.andWhere({ 'ft.type': type });
    if (category_id) query = query.andWhere({ 'ft.category_id': category_id });
    if (from_date) query = query.andWhere('ft.date', '>=', from_date);
    if (to_date) query = query.andWhere('ft.date', '<=', to_date);

    const total = await query.clone().clearSelect().count('ft.id as count').first();
    const p = Math.max(1, parseInt(page, 10));
    const l = Math.min(100, Math.max(1, parseInt(limit, 10)));
    const rows = await query.orderBy('ft.date', 'desc').orderBy('ft.id', 'desc').limit(l).offset((p - 1) * l);
    return { data: rows, pagination: paginationMeta(parseInt(total.count, 10), p, l) };
  },

  async deleteTransaction(orgId, txnId, actorId) {
    const txn = await db('finance_transactions').where({ id: txnId, organization_id: orgId }).first();
    if (!txn) throw new ApiError(404, 'Transaction not found');
    await db('finance_transactions').where({ id: txnId }).del();

    await auditService.log({
      organizationId: orgId, actorId, action: `finance.${txn.type}.delete`,
      entityType: 'finance_transaction', entityId: txnId, details: { amount: txn.amount },
    });

    return { message: 'Transaction deleted' };
  },

  async getSummary(orgId, { from_date, to_date } = {}) {
    let query = db('finance_transactions').where({ organization_id: orgId });
    if (from_date) query = query.andWhere('date', '>=', from_date);
    if (to_date) query = query.andWhere('date', '<=', to_date);

    const result = await query.select('type')
      .sum('amount as total')
      .groupBy('type');

    const summary = { income: 0, expense: 0 };
    result.forEach((r) => { summary[r.type] = parseFloat(r.total) || 0; });
    summary.balance = summary.income - summary.expense;
    return summary;
  },
};

module.exports = financeService;
