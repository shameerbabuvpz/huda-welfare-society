exports.up = async function (knex) {
  await knex.schema.alterTable('organizations', (t) => {
    t.string('logo_url');
    t.string('place');
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('organizations', (t) => {
    t.dropColumn('logo_url');
    t.dropColumn('place');
  });
};
