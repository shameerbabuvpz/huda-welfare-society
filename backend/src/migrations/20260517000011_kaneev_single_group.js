exports.up = async function (knex) {
  await knex.schema.alterTable('kaneev_groups', (t) => {
    t.integer('total_members').unsigned().nullable().alter();
    t.integer('duration_months').unsigned().nullable().alter();
    t.date('start_date').nullable().alter();
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('kaneev_groups', (t) => {
    t.integer('total_members').unsigned().notNullable().alter();
    t.integer('duration_months').unsigned().notNullable().alter();
    t.date('start_date').notNullable().alter();
  });
};
