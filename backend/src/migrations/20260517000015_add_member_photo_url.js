exports.up = function (knex) {
  return knex.schema.alterTable('members', (table) => {
    table.string('photo_url');
  });
};

exports.down = function (knex) {
  return knex.schema.alterTable('members', (table) => {
    table.dropColumn('photo_url');
  });
};
