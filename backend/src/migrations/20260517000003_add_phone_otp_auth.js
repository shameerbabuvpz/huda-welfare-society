exports.up = async function (knex) {
  await knex.schema.alterTable('users', (t) => {
    t.string('phone', 10).unique();
    t.string('name');
  });

  // Make email and password_hash nullable (phone+OTP is primary auth now)
  await knex.raw('ALTER TABLE users ALTER COLUMN email DROP NOT NULL');
  await knex.raw('ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL');
};

exports.down = async function (knex) {
  await knex.schema.alterTable('users', (t) => {
    t.dropColumn('phone');
    t.dropColumn('name');
  });
  await knex.raw('ALTER TABLE users ALTER COLUMN email SET NOT NULL');
  await knex.raw('ALTER TABLE users ALTER COLUMN password_hash SET NOT NULL');
};
