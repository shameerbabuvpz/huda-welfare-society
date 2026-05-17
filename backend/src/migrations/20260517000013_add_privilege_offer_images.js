exports.up = async function (knex) {
  await knex.schema.alterTable('privilege_offers', (t) => {
    t.string('logo_url').nullable();
    t.string('image_url').nullable();
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('privilege_offers', (t) => {
    t.dropColumn('logo_url');
    t.dropColumn('image_url');
  });
};
