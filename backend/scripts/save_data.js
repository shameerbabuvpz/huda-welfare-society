const fs = require('fs');
let raw = fs.readFileSync('/tmp/infacc_raw.txt', 'utf8');
// Strip "Result: " prefix
raw = raw.replace(/^Result:\s*/, '');
// It's a JSON string wrapped in quotes, so parse twice
const data = JSON.parse(JSON.parse(raw));
fs.writeFileSync('/Users/d4-ceo/Desktop/ayalkoottam/backend/infacc_members_data.json', JSON.stringify(data, null, 2));
console.log('Members:', data.totalMembers, 'NHGs:', data.totalNHGs);
