const bcrypt = require('bcryptjs');

exports.seed = async function (knex) {
  const email = process.env.SUPER_ADMIN_EMAIL || 'admin@ayalkoottam.com';
  const password = process.env.SUPER_ADMIN_PASSWORD || 'changeme123';

  const exists = await knex('users').where({ email }).first();
  if (exists) return;

  const password_hash = await bcrypt.hash(password, 12);
  await knex('users').insert({
    email,
    password_hash,
    role: 'super_admin',
    status: 'active',
  });
};
