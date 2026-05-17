exports.up = async function (knex) {
  await knex.schema.alterTable('users', (t) => {
    t.timestamp('last_login_at');
    t.text('photo_url');
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('users', (t) => {
    t.dropColumn('last_login_at');
    t.dropColumn('photo_url');
  });
};
