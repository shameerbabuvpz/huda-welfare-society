/**
 * Add is_guest flag to members table for Kuri guest members
 */
exports.up = async function (knex) {
  const hasCol = await knex.schema.hasColumn('members', 'is_guest');
  if (!hasCol) {
    await knex.schema.alterTable('members', (t) => {
      t.boolean('is_guest').defaultTo(false);
    });
  }
};

exports.down = async function (knex) {
  const hasCol = await knex.schema.hasColumn('members', 'is_guest');
  if (hasCol) {
    await knex.schema.alterTable('members', (t) => {
      t.dropColumn('is_guest');
    });
  }
};
