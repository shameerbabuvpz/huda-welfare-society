exports.up = async function (knex) {
  // ── Kaneev groups (charity/donation fund) ──
  await knex.schema.createTable('kaneev_groups', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.string('name').notNullable();
    t.string('code').notNullable();
    t.integer('total_members').unsigned().notNullable();
    t.decimal('donation_amount', 10, 2).notNullable().defaultTo(100);
    t.integer('duration_months').unsigned().notNullable();
    t.date('start_date').notNullable();
    t.enu('status', ['active', 'completed', 'cancelled']).defaultTo('active');
    t.integer('created_by').unsigned().references('id').inTable('users');
    t.integer('updated_by').unsigned().references('id').inTable('users');
    t.timestamps(true, true);
    t.unique(['organization_id', 'code']);
  });

  // ── Kaneev members ──
  await knex.schema.createTable('kaneev_members', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.integer('kaneev_group_id').unsigned().notNullable().references('id').inTable('kaneev_groups').onDelete('CASCADE');
    t.integer('member_id').unsigned().notNullable().references('id').inTable('members').onDelete('CASCADE');
    t.integer('slot_number').unsigned();
    t.enu('status', ['active', 'withdrawn']).defaultTo('active');
    t.timestamps(true, true);
    t.unique(['kaneev_group_id', 'member_id']);
  });

  // ── Kaneev donations (who paid each month) ──
  await knex.schema.createTable('kaneev_donations', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.integer('kaneev_group_id').unsigned().notNullable().references('id').inTable('kaneev_groups').onDelete('CASCADE');
    t.integer('member_id').unsigned().notNullable().references('id').inTable('members').onDelete('CASCADE');
    t.integer('month_number').unsigned().notNullable();
    t.decimal('amount', 10, 2).notNullable();
    t.date('paid_date');
    t.enu('status', ['paid', 'pending']).defaultTo('paid');
    t.integer('created_by').unsigned().references('id').inTable('users');
    t.timestamps(true, true);
    t.unique(['kaneev_group_id', 'member_id', 'month_number']);
  });

  // ── Kaneev recipients (who received each month) ──
  await knex.schema.createTable('kaneev_recipients', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.integer('kaneev_group_id').unsigned().notNullable().references('id').inTable('kaneev_groups').onDelete('CASCADE');
    t.integer('member_id').unsigned().notNullable().references('id').inTable('members').onDelete('CASCADE');
    t.integer('month_number').unsigned().notNullable();
    t.decimal('total_amount', 10, 2);
    t.date('received_date');
    t.string('reference');
    t.timestamps(true, true);
    // A member can only receive once per group
    t.unique(['kaneev_group_id', 'member_id']);
    // Only one recipient per month
    t.unique(['kaneev_group_id', 'month_number']);
  });
};

exports.down = async function (knex) {
  await knex.schema.dropTableIfExists('kaneev_recipients');
  await knex.schema.dropTableIfExists('kaneev_donations');
  await knex.schema.dropTableIfExists('kaneev_members');
  await knex.schema.dropTableIfExists('kaneev_groups');
};
