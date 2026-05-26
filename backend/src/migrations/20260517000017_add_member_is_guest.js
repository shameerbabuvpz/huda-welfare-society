/**
 * Add is_guest flag to members table for Kuri guest members
 */
exports.up = async function (knex) {
  await knex.schema.alterTable('members', (t) => {
    t.boolean('is_guest').defaultTo(false).after('status');
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('members', (t) => {
    t.dropColumn('is_guest');
  });
};
