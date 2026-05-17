const QRCode = require('qrcode');
const db = require('../config/database');
const ApiError = require('../utils/ApiError');
const { generateCardCode } = require('../utils/generateCode');

const privilegeCardService = {
  async _buildCardResponse(orgId, card, memberId) {
    const member = await db('members')
      .leftJoin('ayalkoottams', 'members.ayalkoottam_id', 'ayalkoottams.id')
      .where({ 'members.id': memberId })
      .select('members.name', 'members.photo_url', 'members.ayalkoottam_id', 'ayalkoottams.name as ayalkoottam_name')
      .first();
    const org = await db('organizations').where({ id: orgId }).first();

    return {
      ...card,
      member_name: member?.name,
      photo_url: member?.photo_url,
      organization_name: org?.name,
      ayalkoottam_name: member?.ayalkoottam_name,
      ayalkoottam_id: member?.ayalkoottam_id,
    };
  },

  async generate(orgId, memberId) {
    // Revoke any existing active card
    await db('privilege_cards')
      .where({ organization_id: orgId, member_id: memberId, status: 'active' })
      .update({ status: 'revoked', updated_at: db.fn.now() });

    const member = await db('members').where({ id: memberId, organization_id: orgId }).first();
    if (!member) throw ApiError.notFound('Member not found');

    const org = await db('organizations').where({ id: orgId }).first();

    const cardCode = generateCardCode();
    const qrPayload = JSON.stringify({
      cardCode,
      memberId: member.id,
      memberCode: member.member_code,
      organization: org.name,
    });

    const qrData = await QRCode.toDataURL(qrPayload);

    const [card] = await db('privilege_cards').insert({
      organization_id: orgId,
      member_id: memberId,
      card_code: cardCode,
      qr_data: qrData,
      status: 'active',
      issued_at: new Date(),
    }).returning('*');

    return this._buildCardResponse(orgId, card, memberId);
  },

  async getByMember(orgId, memberId) {
    let card = await db('privilege_cards')
      .where({ organization_id: orgId, member_id: memberId, status: 'active' })
      .first();
    if (!card) {
      return this.generate(orgId, memberId);
    }

    return this._buildCardResponse(orgId, card, memberId);
  },

  async revoke(orgId, cardId) {
    const [card] = await db('privilege_cards')
      .where({ id: cardId, organization_id: orgId })
      .update({ status: 'revoked', updated_at: db.fn.now() })
      .returning('*');
    if (!card) throw ApiError.notFound('Card not found');
    return card;
  },
};

module.exports = privilegeCardService;
