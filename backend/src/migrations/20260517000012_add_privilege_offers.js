/**
 * Privilege Offers - Partner companies/shops that provide discounts to members.
 * Members scan QR at the shop to redeem offers; redemptions are tracked.
 */
exports.up = async function (knex) {
  await knex.schema.createTable('privilege_offers', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable()
      .references('id').inTable('organizations').onDelete('CASCADE');
    t.string('company_name').notNullable();
    t.text('description');
    t.string('offer_type').notNullable().defaultTo('percentage'); // percentage | flat | freebie
    t.decimal('offer_value', 10, 2); // e.g. 10 for 10%
    t.text('terms_and_conditions');
    t.string('qr_code').notNullable(); // unique code for QR
    t.text('qr_data'); // base64 QR image
    t.string('contact_phone');
    t.string('contact_email');
    t.enu('status', ['active', 'inactive']).defaultTo('active');
    t.integer('created_by').unsigned().references('id').inTable('users');
    t.timestamps(true, true);
  });

  await knex.schema.createTable('privilege_redemptions', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable()
      .references('id').inTable('organizations').onDelete('CASCADE');
    t.integer('offer_id').unsigned().notNullable()
      .references('id').inTable('privilege_offers').onDelete('CASCADE');
    t.integer('member_id').unsigned().notNullable()
      .references('id').inTable('members').onDelete('CASCADE');
    t.timestamp('redeemed_at').defaultTo(knex.fn.now());
    t.text('notes');
    t.timestamps(true, true);
  });
};

exports.down = async function (knex) {
  await knex.schema.dropTableIfExists('privilege_redemptions');
  await knex.schema.dropTableIfExists('privilege_offers');
};
