exports.up = async function (knex) {
  // Simplify ayalkoottams: keep only name, place (rename address to place)
  await knex.schema.alterTable('ayalkoottams', (t) => {
    t.dropColumn('president');
    t.dropColumn('secretary');
    t.dropColumn('ward_number');
    t.dropColumn('phone');
  });
  await knex.raw('ALTER TABLE ayalkoottams RENAME COLUMN address TO place');

  // Add designation to members (president/secretary role per ayalkoottam)
  await knex.schema.alterTable('members', (t) => {
    t.enu('designation', ['president', 'secretary']).nullable();
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('members', (t) => {
    t.dropColumn('designation');
  });
  await knex.raw('ALTER TABLE ayalkoottams RENAME COLUMN place TO address');
  await knex.schema.alterTable('ayalkoottams', (t) => {
    t.string('president');
    t.string('secretary');
    t.string('ward_number');
    t.string('phone');
  });
};
