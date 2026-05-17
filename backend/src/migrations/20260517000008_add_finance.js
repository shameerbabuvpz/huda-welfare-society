exports.up = async function (knex) {
  // ── Finance Categories ──
  await knex.schema.createTable('finance_categories', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.string('name').notNullable();
    t.enu('type', ['income', 'expense']).notNullable();
    t.integer('created_by').unsigned().references('id').inTable('users');
    t.timestamps(true, true);
    t.unique(['organization_id', 'name', 'type']);
  });

  // ── Finance Transactions (Income & Expense entries) ──
  await knex.schema.createTable('finance_transactions', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.integer('category_id').unsigned().notNullable().references('id').inTable('finance_categories').onDelete('RESTRICT');
    t.enu('type', ['income', 'expense']).notNullable();
    t.decimal('amount', 12, 2).notNullable();
    t.date('date').notNullable();
    t.text('description');
    t.integer('created_by').unsigned().references('id').inTable('users');
    t.timestamps(true, true);
  });
};

exports.down = async function (knex) {
  await knex.schema.dropTableIfExists('finance_transactions');
  await knex.schema.dropTableIfExists('finance_categories');
};
