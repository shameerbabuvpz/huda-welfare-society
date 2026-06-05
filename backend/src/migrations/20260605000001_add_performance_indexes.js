/**
 * Performance indexes.
 *
 * Postgres does NOT auto-create indexes on foreign keys, and most list/report
 * queries filter by organization_id + status or join on *_id columns. Without
 * these indexes those queries do sequential scans. We add covering indexes for
 * the hot paths. Columns already covered by the leading column of a UNIQUE
 * constraint (e.g. kaneev_group_id via the unique(group,member,month) index)
 * are intentionally skipped.
 *
 * Uses CREATE INDEX IF NOT EXISTS so the migration is safe to re-run.
 */

const INDEXES = [
  // members — filtered by org+status, joined/filtered by ayalkoottam, resolved by phone/user
  ['idx_members_org_status', 'members', '(organization_id, status)'],
  ['idx_members_ayalkoottam', 'members', '(ayalkoottam_id)'],
  ['idx_members_phone', 'members', '(phone)'],
  ['idx_members_user', 'members', '(user_id)'],

  // users — auth/org lookups
  ['idx_users_org', 'users', '(organization_id)'],

  // assets — list by org+status
  ['idx_assets_org_status', 'assets', '(organization_id, status)'],

  // asset_transactions — issue register / per-asset / per-member history
  ['idx_asset_tx_asset', 'asset_transactions', '(asset_id)'],
  ['idx_asset_tx_member', 'asset_transactions', '(member_id)'],
  ['idx_asset_tx_org_status', 'asset_transactions', '(organization_id, status)'],

  // kaneev — reverse (per-member) lookups
  ['idx_kaneev_members_member', 'kaneev_members', '(member_id)'],
  ['idx_kaneev_donations_member', 'kaneev_donations', '(member_id)'],

  // kuri — group/member joins (kuri_collections + payouts have no unique index)
  ['idx_kuri_collections_group', 'kuri_collections', '(kuri_group_id)'],
  ['idx_kuri_collections_member', 'kuri_collections', '(member_id)'],
  ['idx_kuri_members_member', 'kuri_members', '(member_id)'],
  ['idx_kuri_payouts_group', 'kuri_payouts', '(kuri_group_id)'],
  ['idx_kuri_payouts_member', 'kuri_payouts', '(member_id)'],

  // finance — date-range summaries + category breakdown
  ['idx_finance_tx_org_date', 'finance_transactions', '(organization_id, date)'],
  ['idx_finance_tx_category', 'finance_transactions', '(category_id)'],

  // privilege
  ['idx_priv_cards_member', 'privilege_cards', '(member_id)'],
  ['idx_priv_offers_org_status', 'privilege_offers', '(organization_id, status)'],
  ['idx_priv_redemptions_offer', 'privilege_redemptions', '(offer_id)'],
  ['idx_priv_redemptions_member', 'privilege_redemptions', '(member_id)'],

  // notifications
  ['idx_notif_logs_notification', 'notification_logs', '(notification_id)'],
  ['idx_notif_logs_org_status', 'notification_logs', '(organization_id, status)'],
];

exports.up = async function (knex) {
  for (const [name, table, cols] of INDEXES) {
    await knex.raw(`CREATE INDEX IF NOT EXISTS ${name} ON ${table} ${cols}`);
  }
};

exports.down = async function (knex) {
  for (const [name] of INDEXES) {
    await knex.raw(`DROP INDEX IF EXISTS ${name}`);
  }
};
