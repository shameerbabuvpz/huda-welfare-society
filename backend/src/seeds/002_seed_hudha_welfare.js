exports.seed = async function (knex) {
  // Create organization: Hudha Welfare Society, Pottachira
  const existingOrg = await knex('organizations').where({ name: 'Hudha Welfare Society, Pottachira' }).first();
  if (existingOrg) return;

  const [org] = await knex('organizations').insert({
    name: 'Hudha Welfare Society, Pottachira',
    contact_phone: '9496717816',
    address: 'Pottachira',
    status: 'active',
  }).returning('*');

  // 5 Admins
  const admins = [
    { phone: '9496717816', name: 'Saifuneesa' },
    { phone: '8590864144', name: 'Anwar' },
    { phone: '9645802310', name: 'Fasla' },
    { phone: '9495003602', name: 'Shaheera' },
    { phone: '9656550933', name: 'Shameer' },
  ];

  for (const admin of admins) {
    const exists = await knex('users').where({ phone: admin.phone }).first();
    if (!exists) {
      await knex('users').insert({
        organization_id: org.id,
        phone: admin.phone,
        name: admin.name,
        role: 'admin',
        status: 'active',
      });
    }
  }
};
