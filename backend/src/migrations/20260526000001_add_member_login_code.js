exports.up = async function (knex) {
  // Add login_code and code_changed columns to members table
  return knex.schema.alterTable('members', (t) => {
    // login_code: 4-digit PIN for member login (default: 6789)
    t.string('login_code').notNullable().defaultTo('6789');
    
    // code_changed: track if member has changed the default code
    // false = still using default 6789, needs to be changed on next login
    // true = member has set their own code
    t.boolean('code_changed').notNullable().defaultTo(false);
  });
};

exports.down = async function (knex) {
  return knex.schema.alterTable('members', (t) => {
    t.dropColumn('login_code');
    t.dropColumn('code_changed');
  });
};
