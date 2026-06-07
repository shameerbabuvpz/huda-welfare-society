exports.up = async (knex) => {
  const hasAdj = await knex.schema.hasColumn('weekly_collections', 'adjustment');
  if (!hasAdj) {
    await knex.schema.alterTable('weekly_collections', (t) => {
      t.decimal('adjustment', 12, 2).notNullable().defaultTo(0).after('loan_repayment');
    });
  }
};

exports.down = async (knex) => {
  await knex.schema.alterTable('weekly_collections', (t) => {
    t.dropColumn('adjustment');
  });
};
