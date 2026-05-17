const { v4: uuidv4 } = require('uuid');

function generateMemberCode(prefix = 'MEM') {
  const rand = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `${prefix}-${rand}`;
}

function generateAssetCode(prefix = 'AST') {
  const rand = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `${prefix}-${rand}`;
}

function generateCardCode() {
  return uuidv4().replace(/-/g, '').substring(0, 16).toUpperCase();
}

function generateKuriCode(prefix = 'KURI') {
  const rand = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `${prefix}-${rand}`;
}

module.exports = { generateMemberCode, generateAssetCode, generateCardCode, generateKuriCode };
