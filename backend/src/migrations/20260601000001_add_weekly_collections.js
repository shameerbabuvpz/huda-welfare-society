exports.up = async function (knex) {
  // ── Weekly Ayalkoottam Collections ──
  // One row per ayalkoottam per week. Stores the four transaction figures and
  // a derived net total (deposit - withdrawal - loan + loan_repayment).
  await knex.schema.createTable('weekly_collections', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.integer('ayalkoottam_id').unsigned().notNullable().references('id').inTable('ayalkoottams').onDelete('CASCADE');
    t.date('week_start_date').notNullable();
    t.decimal('deposit', 12, 2).notNullable().defaultTo(0);
    t.decimal('withdrawal', 12, 2).notNullable().defaultTo(0);
    t.decimal('loan', 12, 2).notNullable().defaultTo(0);
    t.decimal('loan_repayment', 12, 2).notNullable().defaultTo(0);
    t.decimal('net_total', 12, 2).notNullable().defaultTo(0);
    t.text('note');
    t.integer('created_by').unsigned().references('id').inTable('users');
    t.integer('updated_by').unsigned().references('id').inTable('users');
    t.timestamps(true, true);
    t.unique(['organization_id', 'ayalkoottam_id', 'week_start_date']);
    t.index(['organization_id', 'week_start_date']);
  });
};

exports.down = async function (knex) {
  await knex.schema.dropTableIfExists('weekly_collections');
};
