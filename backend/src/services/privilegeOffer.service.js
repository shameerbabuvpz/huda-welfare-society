const QRCode = require('qrcode');
const db = require('../config/database');
const ApiError = require('../utils/ApiError');
const { v4: uuidv4 } = require('uuid');

function generateOfferCode() {
  return 'PO-' + uuidv4().replace(/-/g, '').substring(0, 10).toUpperCase();
}

const privilegeOfferService = {
  // ── Admin CRUD ──
  async create(orgId, data, actorId) {
    const qrCode = generateOfferCode();
    const qrPayload = JSON.stringify({
      type: 'privilege_offer',
      code: qrCode,
      orgId,
    });
    const qrData = await QRCode.toDataURL(qrPayload);

    const [offer] = await db('privilege_offers').insert({
      organization_id: orgId,
      company_name: data.company_name,
      description: data.description || null,
      offer_type: data.offer_type || 'percentage',
      offer_value: data.offer_value,
      terms_and_conditions: data.terms_and_conditions || null,
      contact_phone: data.contact_phone || null,
      contact_email: data.contact_email || null,
      logo_url: data.logo_url || null,
      image_url: data.image_url || null,
      qr_code: qrCode,
      qr_data: qrData,
      status: data.status || 'active',
      created_by: actorId,
    }).returning('*');

    return offer;
  },

  async list(orgId, { status } = {}) {
    let query = db('privilege_offers').where({ organization_id: orgId });
    if (status) query = query.andWhere({ status });
    const offers = await query.orderBy('created_at', 'desc');

    // Attach redemption count
    const offerIds = offers.map(o => o.id);
    const counts = await db('privilege_redemptions')
      .whereIn('offer_id', offerIds)
      .groupBy('offer_id')
      .select('offer_id')
      .count('id as count');
    const countMap = {};
    counts.forEach(c => { countMap[c.offer_id] = parseInt(c.count, 10); });

    return offers.map(o => ({ ...o, redemption_count: countMap[o.id] || 0 }));
  },

  async getById(orgId, offerId) {
    const offer = await db('privilege_offers').where({ id: offerId, organization_id: orgId }).first();
    if (!offer) throw ApiError.notFound('Offer not found');

    const redemptions = await db('privilege_redemptions')
      .where({ offer_id: offerId })
      .join('members', 'privilege_redemptions.member_id', 'members.id')
      .select('privilege_redemptions.*', 'members.name as member_name', 'members.member_code')
      .orderBy('privilege_redemptions.redeemed_at', 'desc');

    return { ...offer, redemptions, redemption_count: redemptions.length };
  },

  async update(orgId, offerId, data, actorId) {
    const allowed = {};
    if (data.company_name !== undefined) allowed.company_name = data.company_name;
    if (data.description !== undefined) allowed.description = data.description;
    if (data.offer_type !== undefined) allowed.offer_type = data.offer_type;
    if (data.offer_value !== undefined) allowed.offer_value = data.offer_value;
    if (data.terms_and_conditions !== undefined) allowed.terms_and_conditions = data.terms_and_conditions;
    if (data.contact_phone !== undefined) allowed.contact_phone = data.contact_phone;
    if (data.contact_email !== undefined) allowed.contact_email = data.contact_email;
    if (data.logo_url !== undefined) allowed.logo_url = data.logo_url;
    if (data.image_url !== undefined) allowed.image_url = data.image_url;
    if (data.status !== undefined) allowed.status = data.status;

    const [offer] = await db('privilege_offers')
      .where({ id: offerId, organization_id: orgId })
      .update({ ...allowed, updated_at: db.fn.now() })
      .returning('*');
    if (!offer) throw ApiError.notFound('Offer not found');
    return offer;
  },

  async delete(orgId, offerId) {
    const deleted = await db('privilege_offers').where({ id: offerId, organization_id: orgId }).del();
    if (!deleted) throw ApiError.notFound('Offer not found');
    return { success: true };
  },

  // ── Member-facing ──
  async listActive(orgId) {
    return db('privilege_offers')
      .where({ organization_id: orgId, status: 'active' })
      .orderBy('created_at', 'desc');
  },

  async redeem(orgId, qrCode, memberId) {
    const offer = await db('privilege_offers')
      .where({ organization_id: orgId, qr_code: qrCode, status: 'active' })
      .first();
    if (!offer) throw ApiError.notFound('Invalid or inactive offer QR code');

    const [redemption] = await db('privilege_redemptions').insert({
      organization_id: orgId,
      offer_id: offer.id,
      member_id: memberId,
      redeemed_at: new Date(),
    }).returning('*');

    return { ...redemption, company_name: offer.company_name, offer_value: offer.offer_value, offer_type: offer.offer_type };
  },

  async myRedemptions(orgId, memberId) {
    return db('privilege_redemptions')
      .where({ 'privilege_redemptions.organization_id': orgId, 'privilege_redemptions.member_id': memberId })
      .join('privilege_offers', 'privilege_redemptions.offer_id', 'privilege_offers.id')
      .select(
        'privilege_redemptions.*',
        'privilege_offers.company_name',
        'privilege_offers.offer_type',
        'privilege_offers.offer_value',
        'privilege_offers.description as offer_description',
      )
      .orderBy('privilege_redemptions.redeemed_at', 'desc');
  },
};

module.exports = privilegeOfferService;
