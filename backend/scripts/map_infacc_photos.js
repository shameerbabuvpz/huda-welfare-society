#!/usr/bin/env node
require('dotenv').config();
const db = require('../src/config/database');
const fs = require('fs');
const path = require('path');

async function mapPhotos() {
  const data = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'infacc_members_data.json'), 'utf8'));

  // Build phone -> photo map
  const phoneToPhoto = {};
  for (const nhg of data.nhgGroups) {
    for (const m of nhg.members) {
      if (m.phone && m.photo) {
        phoneToPhoto[m.phone] = m.photo;
      }
    }
  }
  console.log('Total photos in INFACC data:', Object.keys(phoneToPhoto).length);

  // Update members table (matched by phone)
  const members = await db('members').whereNotNull('phone').select('id', 'phone', 'photo_url');
  console.log('Members in DB:', members.length);

  let membersUpdated = 0;
  for (const member of members) {
    const photo = phoneToPhoto[member.phone];
    if (photo && !member.photo_url) {
      await db('members').where({ id: member.id }).update({ photo_url: photo });
      membersUpdated++;
    }
  }
  console.log(`Members updated with INFACC photos: ${membersUpdated}`);

  // Also update users table for those who already have accounts
  const users = await db('users').whereNotNull('phone').select('id', 'phone', 'photo_url');
  let usersUpdated = 0;
  for (const user of users) {
    const photo = phoneToPhoto[user.phone];
    if (photo && !user.photo_url) {
      await db('users').where({ id: user.id }).update({ photo_url: photo });
      usersUpdated++;
    }
  }
  console.log(`Users updated with INFACC photos: ${usersUpdated}`);

  await db.destroy();
}

mapPhotos().catch((err) => {
  console.error('Failed:', err);
  db.destroy();
  process.exit(1);
});
