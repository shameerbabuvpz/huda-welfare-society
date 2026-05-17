#!/usr/bin/env node
/**
 * Extract members and NHG (ayalkoottam) data from app.infacc.org
 * Outputs: backend/infacc_members_data.json
 */
const https = require('https');
const fs = require('fs');
const path = require('path');

const COOKIE = 'advanced-backend=ae4d82tmpq44kss593htk0uhkd; _csrf-backend=e489fa5d036de5fb3bc520836cb26a48bb13d876850227bca9f56a330f0d3e3ca%3A2%3A%7Bi%3A0%3Bs%3A13%3A%22_csrf-backend%22%3Bi%3A1%3Bs%3A32%3A%22qLV6-HyErpYpXBs_hm6eqlHf4iEIkctK%22%3B%7D';
const BASE_URL = 'https://app.infacc.org/backend/web/member/index';
const TOTAL_PAGES = 50;

function fetchPage(page) {
  return new Promise((resolve, reject) => {
    const url = `${BASE_URL}?page=${page}`;
    https.get(url, {
      headers: { 'Cookie': COOKIE, 'User-Agent': 'Mozilla/5.0' }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    }).on('error', reject);
  });
}

function parseMembers(html) {
  const members = [];
  // Match table rows by data-key attribute (each member row has data-key)
  const rowRegex = /<tr[^>]*data-key="[^"]*"[^>]*>([\s\S]*?)<\/tr>/g;
  let rowMatch;
  
  while ((rowMatch = rowRegex.exec(html)) !== null) {
    const row = rowMatch[1];
    // Extract all <td> cells - handle multiline
    const cells = [];
    const cellRegex = /<td[^>]*>([\s\S]*?)<\/td>/g;
    let cellMatch;
    while ((cellMatch = cellRegex.exec(row)) !== null) {
      cells.push(cellMatch[1]);
    }
    
    if (cells.length < 5) continue;
    
    // Cell 2 (index 2): Username - contains phone and [NAME]
    const usernameText = cells[2].replace(/<[^>]+>/g, '').trim();
    const phoneMatch = usernameText.match(/(\d{10})/);
    const nameMatch = usernameText.match(/\[\s*(.+?)\s*\]/);
    
    // Cell 3 (index 3): Member ID
    const memberIdText = cells[3].replace(/<[^>]+>/g, '').trim();
    
    // Cell 4 (index 4): NHG - contains NHG name and [NHG code]
    const nhgText = cells[4].replace(/<[^>]+>/g, '').trim();
    const nhgCodeMatch = nhgText.match(/\[\s*(PKD\/[\d\/]+)\s*\]/);
    const nhgName = nhgText.replace(/\[.*?\]/, '').trim();
    
    // Cell 1 (index 1): Photo link
    const photoMatch = cells[1].match(/file=([^"&]+)/);
    
    members.push({
      phone: phoneMatch ? phoneMatch[1] : '',
      name: nameMatch ? nameMatch[1].trim() : '',
      memberId: memberIdText,
      nhgName: nhgName,
      nhgCode: nhgCodeMatch ? nhgCodeMatch[1] : '',
      photo: photoMatch ? `https://app.infacc.org/backend/web/resizes/index?type=user&size=0_0&file=${photoMatch[1]}` : ''
    });
  }
  
  return members;
}

async function main() {
  console.log(`Extracting members from ${TOTAL_PAGES} pages...`);
  const allMembers = [];
  
  for (let p = 1; p <= TOTAL_PAGES; p++) {
    try {
      const html = await fetchPage(p);
      const members = parseMembers(html);
      allMembers.push(...members);
      process.stdout.write(`\rPage ${p}/${TOTAL_PAGES} - ${allMembers.length} members`);
    } catch (err) {
      console.error(`\nError on page ${p}:`, err.message);
    }
  }
  
  console.log(`\n\nTotal members extracted: ${allMembers.length}`);
  
  // Group by NHG
  const nhgMap = {};
  allMembers.forEach(m => {
    const key = m.nhgCode || m.nhgName || 'UNKNOWN';
    if (!nhgMap[key]) {
      nhgMap[key] = { nhgName: m.nhgName, nhgCode: m.nhgCode, members: [] };
    }
    nhgMap[key].members.push({
      phone: m.phone,
      name: m.name,
      memberId: m.memberId,
      photo: m.photo
    });
  });
  
  const nhgGroups = Object.values(nhgMap);
  console.log(`Total unique NHGs: ${nhgGroups.length}`);
  
  const result = {
    extractedAt: new Date().toISOString(),
    totalMembers: allMembers.length,
    totalNHGs: nhgGroups.length,
    nhgGroups: nhgGroups
  };
  
  const outPath = path.join(__dirname, '..', 'infacc_members_data.json');
  fs.writeFileSync(outPath, JSON.stringify(result, null, 2));
  console.log(`\nSaved to: ${outPath}`);
  
  // Print NHG summary
  console.log('\n── NHG Summary ──');
  nhgGroups.sort((a, b) => b.members.length - a.members.length);
  nhgGroups.forEach(g => {
    console.log(`  ${g.nhgCode || 'N/A'} | ${g.nhgName} | ${g.members.length} members`);
  });
}

main().catch(console.error);
