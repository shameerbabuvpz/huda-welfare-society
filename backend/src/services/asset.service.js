const db = require('../config/database');
const ApiError = require('../utils/ApiError');
const { generateAssetCode } = require('../utils/generateCode');
const { paginationMeta } = require('../utils/pagination');
const auditService = require('./audit.service');

const NON_ISSUABLE_CONDITIONS = ['damaged', 'missing'];

const assetService = {
  async create(orgId, data, actorId) {
    const assetCode = data.asset_code || generateAssetCode();
    const [asset] = await db('assets').insert({
      organization_id: orgId,
      name: data.name,
      description: data.description,
      asset_code: assetCode,
      category: data.category,
      purchase_date: data.purchase_date || null,
      cost: data.cost || null,
      status: 'available',
      condition: 'working',
      created_by: actorId,
      updated_by: actorId,
    }).returning('*');

    await auditService.log({
      organizationId: orgId, actorId, action: 'asset.create',
      entityType: 'asset', entityId: asset.id, details: { name: data.name },
    });

    return asset;
  },

  async list(orgId, { page = 1, limit = 20, status, condition, search }) {
    let query = db('assets').where({ organization_id: orgId });
    if (status) query = query.andWhere({ status });
    if (condition) query = query.andWhere({ condition });
    if (search) {
      query = query.andWhere(function () {
        this.where('name', 'ilike', `%${search}%`).orWhere('asset_code', 'ilike', `%${search}%`);
      });
    }
    const total = await query.clone().count('id as count').first();
    const p = Math.max(1, parseInt(page, 10));
    const l = Math.min(100, Math.max(1, parseInt(limit, 10)));
    const rows = await query.orderBy('id', 'desc').limit(l).offset((p - 1) * l);
    return { data: rows, pagination: paginationMeta(parseInt(total.count, 10), p, l) };
  },

  // List only assets available for issuing (status=available, condition=working)
  async listAvailable(orgId, { search } = {}) {
    let query = db('assets').where({ organization_id: orgId, status: 'available', condition: 'working' });
    if (search) {
      query = query.andWhere(function () {
        this.where('name', 'ilike', `%${search}%`).orWhere('asset_code', 'ilike', `%${search}%`);
      });
    }
    return await query.orderBy('name', 'asc');
  },

  async getById(orgId, assetId) {
    const asset = await db('assets').where({ id: assetId, organization_id: orgId }).first();
    if (!asset) throw ApiError.notFound('Asset not found');
    return asset;
  },

  async update(orgId, assetId, data, actorId) {
    const allowed = ['name', 'description', 'category', 'purchase_date', 'cost', 'condition', 'status'];
    const updateData = {};
    for (const key of allowed) {
      if (data[key] !== undefined) updateData[key] = data[key];
    }
    updateData.updated_by = actorId;
    updateData.updated_at = db.fn.now();

    const [asset] = await db('assets')
      .where({ id: assetId, organization_id: orgId })
      .update(updateData)
      .returning('*');
    if (!asset) throw ApiError.notFound('Asset not found');
    return asset;
  },

  async issue(orgId, assetId, { memberId, dueDate, remarks }, actorId) {
    const asset = await db('assets').where({ id: assetId, organization_id: orgId }).first();
    if (!asset) throw ApiError.notFound('Asset not found');
    if (asset.status === 'issued') throw ApiError.conflict('Asset is already issued to someone');
    if (asset.status === 'retired') throw ApiError.conflict('Asset is retired and cannot be issued');
    if (NON_ISSUABLE_CONDITIONS.includes(asset.condition)) {
      throw ApiError.conflict(`Asset is marked as "${asset.condition}" and cannot be issued`);
    }

    const member = await db('members').where({ id: memberId, organization_id: orgId }).first();
    if (!member) throw ApiError.notFound('Member not found in this organization');

    const [txn] = await db('asset_transactions').insert({
      organization_id: orgId,
      asset_id: assetId,
      member_id: memberId,
      issued_by: actorId,
      issue_date: new Date(),
      due_date: dueDate || null,
      issue_remarks: remarks || null,
      status: 'issued',
    }).returning('*');

    await db('assets').where({ id: assetId }).update({ status: 'issued', updated_at: db.fn.now() });

    await auditService.log({
      organizationId: orgId, actorId, action: 'asset.issue',
      entityType: 'asset_transaction', entityId: txn.id,
      details: { assetId, memberId, assetName: asset.name },
    });

    return txn;
  },

  async returnAsset(orgId, assetId, { remarks, conditionOnReturn }, actorId) {
    const txn = await db('asset_transactions')
      .where({ asset_id: assetId, organization_id: orgId, status: 'issued' })
      .orderBy('id', 'desc')
      .first();
    if (!txn) throw ApiError.notFound('No active issue record found for this asset');

    const condition = conditionOnReturn || 'working';
    let txnStatus = 'returned';
    if (condition === 'damaged') txnStatus = 'returned_damaged';
    else if (condition === 'missing') txnStatus = 'returned_missing';

    const [updated] = await db('asset_transactions')
      .where({ id: txn.id })
      .update({
        return_date: new Date(),
        status: txnStatus,
        remarks,
        condition_on_return: condition,
        returned_by: actorId,
        updated_at: db.fn.now(),
      })
      .returning('*');

    // Update asset status based on return condition
    let newAssetStatus = 'available';
    if (condition === 'damaged') newAssetStatus = 'damaged';
    else if (condition === 'missing') newAssetStatus = 'missing';

    await db('assets').where({ id: assetId }).update({
      status: newAssetStatus,
      condition: condition,
      updated_at: db.fn.now(),
    });

    await auditService.log({
      organizationId: orgId, actorId, action: 'asset.return',
      entityType: 'asset_transaction', entityId: txn.id,
      details: { assetId, conditionOnReturn: condition },
    });

    return updated;
  },

  // Issue Register: paginated list of all transactions (issue/return history)
  async issueRegister(orgId, { page = 1, limit = 20, status, search }) {
    let query = db('asset_transactions')
      .where({ 'asset_transactions.organization_id': orgId })
      .leftJoin('members', 'asset_transactions.member_id', 'members.id')
      .leftJoin('assets', 'asset_transactions.asset_id', 'assets.id')
      .leftJoin('users as issuer', 'asset_transactions.issued_by', 'issuer.id')
      .select(
        'asset_transactions.*',
        'members.name as member_name',
        'members.phone as member_phone',
        'assets.name as asset_name',
        'assets.asset_code',
        'assets.category as asset_category',
        'issuer.email as issued_by_email'
      );

    if (status) query = query.andWhere('asset_transactions.status', status);
    if (search) {
      query = query.andWhere(function () {
        this.where('assets.name', 'ilike', `%${search}%`)
          .orWhere('members.name', 'ilike', `%${search}%`)
          .orWhere('assets.asset_code', 'ilike', `%${search}%`);
      });
    }

    const countQuery = db('asset_transactions').where({ organization_id: orgId });
    if (status) countQuery.andWhere({ status });
    const total = await countQuery.count('id as count').first();

    const p = Math.max(1, parseInt(page, 10));
    const l = Math.min(100, Math.max(1, parseInt(limit, 10)));
    const rows = await query.orderBy('asset_transactions.id', 'desc').limit(l).offset((p - 1) * l);
    return { data: rows, pagination: paginationMeta(parseInt(total.count, 10), p, l) };
  },

  // Damaged/Missing report
  async damageReport(orgId, { page = 1, limit = 20 }) {
    let query = db('assets')
      .where({ organization_id: orgId })
      .andWhere(function () {
        this.where('condition', 'damaged').orWhere('condition', 'missing');
      });

    const total = await query.clone().count('id as count').first();
    const p = Math.max(1, parseInt(page, 10));
    const l = Math.min(100, Math.max(1, parseInt(limit, 10)));
    const rows = await query.orderBy('updated_at', 'desc').limit(l).offset((p - 1) * l);

    // Attach last transaction info for each damaged/missing asset
    const assetIds = rows.map(r => r.id);
    const lastTxns = assetIds.length > 0
      ? await db('asset_transactions')
          .whereIn('asset_id', assetIds)
          .andWhere('organization_id', orgId)
          .leftJoin('members', 'asset_transactions.member_id', 'members.id')
          .select('asset_transactions.*', 'members.name as member_name')
          .orderBy('asset_transactions.id', 'desc')
      : [];

    const txnMap = {};
    for (const txn of lastTxns) {
      if (!txnMap[txn.asset_id]) txnMap[txn.asset_id] = txn;
    }

    const data = rows.map(asset => ({
      ...asset,
      last_transaction: txnMap[asset.id] || null,
    }));

    return { data, pagination: paginationMeta(parseInt(total.count, 10), p, l) };
  },

  async transactionHistory(orgId, assetId, { page = 1, limit = 20 }) {
    let query = db('asset_transactions')
      .where({ 'asset_transactions.organization_id': orgId, 'asset_transactions.asset_id': assetId })
      .leftJoin('members', 'asset_transactions.member_id', 'members.id')
      .select('asset_transactions.*', 'members.name as member_name');

    const total = await db('asset_transactions').where({ organization_id: orgId, asset_id: assetId }).count('id as count').first();
    const p = Math.max(1, parseInt(page, 10));
    const l = Math.min(100, Math.max(1, parseInt(limit, 10)));
    const rows = await query.orderBy('asset_transactions.id', 'desc').limit(l).offset((p - 1) * l);
    return { data: rows, pagination: paginationMeta(parseInt(total.count, 10), p, l) };
  },

  async memberAssets(orgId, memberId) {
    const rows = await db('asset_transactions')
      .where({ 'asset_transactions.organization_id': orgId, 'asset_transactions.member_id': memberId, 'asset_transactions.status': 'issued' })
      .join('assets', 'asset_transactions.asset_id', 'assets.id')
      .select('asset_transactions.*', 'assets.name as asset_name', 'assets.asset_code', 'assets.category as asset_category');
    return rows;
  },

  // Summary stats for dashboard
  async stats(orgId) {
    const total = await db('assets').where({ organization_id: orgId }).count('id as count').first();
    const available = await db('assets').where({ organization_id: orgId, status: 'available', condition: 'working' }).count('id as count').first();
    const issued = await db('assets').where({ organization_id: orgId, status: 'issued' }).count('id as count').first();
    const damaged = await db('assets').where({ organization_id: orgId, condition: 'damaged' }).count('id as count').first();
    const missing = await db('assets').where({ organization_id: orgId, condition: 'missing' }).count('id as count').first();

    return {
      total: parseInt(total.count, 10),
      available: parseInt(available.count, 10),
      issued: parseInt(issued.count, 10),
      damaged: parseInt(damaged.count, 10),
      missing: parseInt(missing.count, 10),
    };
  },

  async delete(orgId, assetId, actorId) {
    // Check if asset can be deleted (must not be issued)
    const asset = await db('assets').where({ id: assetId, organization_id: orgId }).first();
    if (!asset) throw ApiError.notFound('Asset not found');
    if (asset.status === 'issued') throw ApiError.conflict('Cannot delete asset that is currently issued');

    // Delete the asset
    await db('assets').where({ id: assetId, organization_id: orgId }).del();

    // Log the action
    await auditService.log({
      organizationId: orgId,
      actorId,
      action: 'asset.delete',
      entityType: 'asset',
      entityId: assetId,
      details: { name: asset.name, assetCode: asset.asset_code },
    });
  },
};

module.exports = assetService;
