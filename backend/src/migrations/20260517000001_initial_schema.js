exports.up = async function (knex) {
  // ── Organizations ──
  await knex.schema.createTable('organizations', (t) => {
    t.increments('id').primary();
    t.string('name').notNullable();
    t.string('contact_email');
    t.string('contact_phone');
    t.text('address');
    t.enu('status', ['active', 'inactive']).defaultTo('active');
    t.timestamps(true, true);
  });

  // ── Users (auth accounts) ──
  await knex.schema.createTable('users', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().references('id').inTable('organizations').onDelete('SET NULL');
    t.string('email').notNullable().unique();
    t.string('password_hash').notNullable();
    t.enu('role', ['super_admin', 'admin', 'member']).notNullable().defaultTo('member');
    t.enu('status', ['active', 'inactive']).defaultTo('active');
    t.string('fcm_token');
    t.timestamps(true, true);
  });

  // ── Members ──
  await knex.schema.createTable('members', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.integer('user_id').unsigned().references('id').inTable('users').onDelete('SET NULL');
    t.string('member_code').notNullable();
    t.string('name').notNullable();
    t.string('phone');
    t.string('email');
    t.text('address');
    t.date('join_date').defaultTo(knex.fn.now());
    t.enu('status', ['active', 'inactive']).defaultTo('active');
    t.integer('created_by').unsigned().references('id').inTable('users');
    t.integer('updated_by').unsigned().references('id').inTable('users');
    t.timestamps(true, true);
    t.unique(['organization_id', 'member_code']);
  });

  // ── Privilege Cards ──
  await knex.schema.createTable('privilege_cards', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.integer('member_id').unsigned().notNullable().references('id').inTable('members').onDelete('CASCADE');
    t.string('card_code').notNullable();
    t.text('qr_data');
    t.enu('status', ['active', 'revoked']).defaultTo('active');
    t.timestamp('issued_at').defaultTo(knex.fn.now());
    t.timestamps(true, true);
    t.unique(['organization_id', 'card_code']);
  });

  // ── Assets ──
  await knex.schema.createTable('assets', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.string('name').notNullable();
    t.text('description');
    t.string('asset_code').notNullable();
    t.string('category');
    t.enu('status', ['available', 'issued', 'retired']).defaultTo('available');
    t.integer('created_by').unsigned().references('id').inTable('users');
    t.integer('updated_by').unsigned().references('id').inTable('users');
    t.timestamps(true, true);
    t.unique(['organization_id', 'asset_code']);
  });

  // ── Asset Transactions ──
  await knex.schema.createTable('asset_transactions', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.integer('asset_id').unsigned().notNullable().references('id').inTable('assets').onDelete('CASCADE');
    t.integer('member_id').unsigned().notNullable().references('id').inTable('members').onDelete('CASCADE');
    t.integer('issued_by').unsigned().references('id').inTable('users');
    t.date('issue_date').notNullable();
    t.date('due_date');
    t.date('return_date');
    t.enu('status', ['issued', 'returned']).defaultTo('issued');
    t.text('remarks');
    t.timestamps(true, true);
  });

  // ── Kuri Groups ──
  await knex.schema.createTable('kuri_groups', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.string('name').notNullable();
    t.string('code').notNullable();
    t.integer('total_members').notNullable();
    t.decimal('monthly_amount', 12, 2).notNullable();
    t.integer('duration_months').notNullable();
    t.date('start_date').notNullable();
    t.enu('status', ['active', 'completed', 'cancelled']).defaultTo('active');
    t.integer('created_by').unsigned().references('id').inTable('users');
    t.integer('updated_by').unsigned().references('id').inTable('users');
    t.timestamps(true, true);
    t.unique(['organization_id', 'code']);
  });

  // ── Kuri Members ──
  await knex.schema.createTable('kuri_members', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.integer('kuri_group_id').unsigned().notNullable().references('id').inTable('kuri_groups').onDelete('CASCADE');
    t.integer('member_id').unsigned().notNullable().references('id').inTable('members').onDelete('CASCADE');
    t.integer('slot_number');
    t.enu('status', ['active', 'withdrawn']).defaultTo('active');
    t.timestamp('joined_at').defaultTo(knex.fn.now());
    t.timestamps(true, true);
    t.unique(['kuri_group_id', 'member_id']);
  });

  // ── Kuri Collections ──
  await knex.schema.createTable('kuri_collections', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.integer('kuri_group_id').unsigned().notNullable().references('id').inTable('kuri_groups').onDelete('CASCADE');
    t.integer('member_id').unsigned().notNullable().references('id').inTable('members').onDelete('CASCADE');
    t.integer('month_number').notNullable();
    t.decimal('amount', 12, 2).notNullable();
    t.date('paid_date');
    t.enu('status', ['paid', 'pending', 'overdue']).defaultTo('pending');
    t.integer('created_by').unsigned().references('id').inTable('users');
    t.timestamps(true, true);
  });

  // ── Kuri Winners ──
  await knex.schema.createTable('kuri_winners', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.integer('kuri_group_id').unsigned().notNullable().references('id').inTable('kuri_groups').onDelete('CASCADE');
    t.integer('member_id').unsigned().notNullable().references('id').inTable('members').onDelete('CASCADE');
    t.integer('month_number').notNullable();
    t.date('won_date').notNullable();
    t.timestamps(true, true);
    t.unique(['kuri_group_id', 'month_number']); // one winner per month per group
    t.unique(['kuri_group_id', 'member_id']);     // each member wins only once
  });

  // ── Kuri Payouts ──
  await knex.schema.createTable('kuri_payouts', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.integer('kuri_group_id').unsigned().notNullable().references('id').inTable('kuri_groups').onDelete('CASCADE');
    t.integer('member_id').unsigned().notNullable().references('id').inTable('members').onDelete('CASCADE');
    t.integer('kuri_winner_id').unsigned().notNullable().references('id').inTable('kuri_winners').onDelete('CASCADE');
    t.decimal('amount', 12, 2).notNullable();
    t.date('payout_date').notNullable();
    t.string('reference');
    t.integer('created_by').unsigned().references('id').inTable('users');
    t.timestamps(true, true);
  });

  // ── Notifications ──
  await knex.schema.createTable('notifications', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.string('title').notNullable();
    t.text('body').notNullable();
    t.enu('audience_type', ['all', 'specific']).defaultTo('all');
    t.integer('created_by').unsigned().references('id').inTable('users');
    t.timestamps(true, true);
  });

  // ── Notification Logs ──
  await knex.schema.createTable('notification_logs', (t) => {
    t.increments('id').primary();
    t.integer('notification_id').unsigned().notNullable().references('id').inTable('notifications').onDelete('CASCADE');
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.integer('member_id').unsigned().references('id').inTable('members').onDelete('SET NULL');
    t.enu('status', ['sent', 'failed', 'pending']).defaultTo('pending');
    t.text('error');
    t.timestamp('sent_at');
    t.timestamps(true, true);
  });

  // ── Audit Logs ──
  await knex.schema.createTable('audit_logs', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().references('id').inTable('organizations').onDelete('SET NULL');
    t.integer('actor_id').unsigned().references('id').inTable('users');
    t.string('action').notNullable();
    t.string('entity_type').notNullable();
    t.integer('entity_id');
    t.jsonb('details');
    t.timestamp('created_at').defaultTo(knex.fn.now());
  });
};

exports.down = async function (knex) {
  const tables = [
    'audit_logs',
    'notification_logs',
    'notifications',
    'kuri_payouts',
    'kuri_winners',
    'kuri_collections',
    'kuri_members',
    'kuri_groups',
    'asset_transactions',
    'assets',
    'privilege_cards',
    'members',
    'users',
    'organizations',
  ];
  for (const table of tables) {
    await knex.schema.dropTableIfExists(table);
  }
};
