require('dotenv').config();
const knex = require('knex');
const config = require('../knexfile');
const fs = require('fs');
const path = require('path');

const db = knex(config.development);

async function importData() {
  const dataPath = path.join(__dirname, '..', 'infacc_members_data.json');
  const data = JSON.parse(fs.readFileSync(dataPath, 'utf8'));

  console.log(`Importing ${data.totalMembers} members across ${data.totalNHGs} NHGs...`);

  // Organization ID for Hudha Welfare
  const org = await db('organizations').where('name', 'like', '%Hudha%').first();
  if (!org) {
    console.error('Organization not found! Make sure seeds have been run.');
    process.exit(1);
  }
  const orgId = org.id;
  console.log(`Organization: ${org.name} (ID: ${orgId})`);

  // Clear existing ayalkoottams and members for this org (fresh import)
  const existingMembers = await db('members').where('organization_id', orgId).count('* as cnt');
  const existingAK = await db('ayalkoottams').where('organization_id', orgId).count('* as cnt');
  console.log(`Existing: ${existingMembers[0].cnt} members, ${existingAK[0].cnt} ayalkoottams`);

  // Delete members first (FK constraint), then ayalkoottams
  await db('members').where('organization_id', orgId).del();
  await db('ayalkoottams').where('organization_id', orgId).del();
  console.log('Cleared existing data.');

  let totalMembersInserted = 0;
  let totalAKCreated = 0;

  for (const nhg of data.nhgGroups) {
    // Extract place from NHG name (after last space-separated location identifier)
    const place = nhg.nhgName;

    // Create ayalkoottam
    const [ak] = await db('ayalkoottams').insert({
      organization_id: orgId,
      name: nhg.nhgName,
      code: nhg.nhgCode,
      place: place,
      status: 'active',
    }).returning('*');

    totalAKCreated++;

    // Insert members for this NHG
    for (const member of nhg.members) {
      await db('members').insert({
        organization_id: orgId,
        ayalkoottam_id: ak.id,
        member_code: member.memberId,
        name: member.name,
        phone: member.phone,
        status: 'active',
      });
      totalMembersInserted++;
    }

    console.log(`  ✓ ${nhg.nhgCode} - ${nhg.nhgName}: ${nhg.members.length} members`);
  }

  console.log(`\n✅ Import complete!`);
  console.log(`   Ayalkoottams created: ${totalAKCreated}`);
  console.log(`   Members inserted: ${totalMembersInserted}`);

  await db.destroy();
}

importData().catch((err) => {
  console.error('Import failed:', err);
  db.destroy();
  process.exit(1);
});
