exports.up = async function (knex) {
  await knex.schema.alterTable('assets', (t) => {
    t.date('purchase_date').nullable();
    t.decimal('cost', 12, 2).nullable();
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('assets', (t) => {
    t.dropColumn('purchase_date');
    t.dropColumn('cost');
  });
};
