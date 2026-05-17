exports.up = async function (knex) {
  await knex.schema.createTable('kaneev_balance_log', (t) => {
    t.increments('id').primary();
    t.integer('organization_id').unsigned().notNullable().references('id').inTable('organizations').onDelete('CASCADE');
    t.integer('kaneev_group_id').unsigned().notNullable().references('id').inTable('kaneev_groups').onDelete('CASCADE');
    t.integer('month_number').unsigned().notNullable();
    t.decimal('total_collected', 10, 2).notNullable().defaultTo(0);
    t.decimal('total_distributed', 10, 2).notNullable().defaultTo(0);
    t.decimal('month_balance', 10, 2).notNullable().defaultTo(0);
    t.decimal('cumulative_balance', 10, 2).notNullable().defaultTo(0);
    t.text('notes');
    t.integer('created_by').unsigned().references('id').inTable('users');
    t.timestamps(true, true);
  });
};

exports.down = async function (knex) {
  await knex.schema.dropTableIfExists('kaneev_balance_log');
};
