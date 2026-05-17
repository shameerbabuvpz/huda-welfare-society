exports.up = async function (knex) {
  // Allow multiple recipients per month — drop the per-month unique constraint
  await knex.schema.alterTable('kaneev_recipients', (t) => {
    t.dropUnique(['kaneev_group_id', 'month_number']);
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('kaneev_recipients', (t) => {
    t.unique(['kaneev_group_id', 'month_number']);
  });
};
