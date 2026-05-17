const ExcelJS = require('exceljs');
const PDFDocument = require('pdfkit');
const db = require('../config/database');

const exportService = {
  // ═══════════════════════════════════════════════════════════════
  // MEMBERS EXPORT
  // ═══════════════════════════════════════════════════════════════
  async getMembersData(orgId, { ayalkoottamId } = {}) {
    let query = db('members')
      .where({ 'members.organization_id': orgId })
      .leftJoin('ayalkoottams', 'members.ayalkoottam_id', 'ayalkoottams.id')
      .select(
        'members.id', 'members.name', 'members.member_code', 'members.phone',
        'members.address', 'members.status', 'members.designation',
        'members.created_at', 'ayalkoottams.name as ayalkoottam_name'
      )
      .orderBy('members.name');

    if (ayalkoottamId) {
      query = query.andWhere({ 'members.ayalkoottam_id': ayalkoottamId });
    }

    return query;
  },

  async membersToExcel(orgId, { ayalkoottamId } = {}) {
    const members = await this.getMembersData(orgId, { ayalkoottamId });
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Members');

    sheet.columns = [
      { header: 'Sl No', key: 'sl', width: 8 },
      { header: 'Member Code', key: 'member_code', width: 15 },
      { header: 'Name', key: 'name', width: 25 },
      { header: 'Phone', key: 'phone', width: 15 },
      { header: 'Ayalkoottam', key: 'ayalkoottam_name', width: 20 },
      { header: 'Designation', key: 'designation', width: 15 },
      { header: 'Address', key: 'address', width: 30 },
      { header: 'Status', key: 'status', width: 12 },
    ];

    // Style header row
    sheet.getRow(1).font = { bold: true };
    sheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE8F5E9' } };

    members.forEach((m, i) => {
      sheet.addRow({
        sl: i + 1,
        member_code: m.member_code,
        name: m.name,
        phone: m.phone || '',
        ayalkoottam_name: m.ayalkoottam_name || '',
        designation: m.designation || '',
        address: m.address || '',
        status: m.status,
      });
    });

    return workbook.xlsx.writeBuffer();
  },

  async membersToPdf(orgId, { ayalkoottamId } = {}) {
    const members = await this.getMembersData(orgId, { ayalkoottamId });
    const org = await db('organizations').where({ id: orgId }).first();

    let title = `${org.name} - Members List`;
    if (ayalkoottamId) {
      const ak = await db('ayalkoottams').where({ id: ayalkoottamId }).first();
      if (ak) title += ` (${ak.name})`;
    }

    return this._generateTablePdf(title, {
      headers: ['#', 'Code', 'Name', 'Phone', 'Ayalkoottam', 'Status'],
      widths: [25, 60, 120, 80, 100, 50],
      rows: members.map((m, i) => [
        String(i + 1), m.member_code || '', m.name, m.phone || '',
        m.ayalkoottam_name || '', m.status,
      ]),
    });
  },

  // ═══════════════════════════════════════════════════════════════
  // KURI REPORT
  // ═══════════════════════════════════════════════════════════════
  async getKuriData(orgId, groupId) {
    const group = await db('kuri_groups').where({ id: groupId, organization_id: orgId }).first();
    if (!group) return null;

    const collections = await db('kuri_collections')
      .where({ 'kuri_collections.organization_id': orgId, 'kuri_collections.kuri_group_id': groupId })
      .join('members', 'kuri_collections.member_id', 'members.id')
      .select('kuri_collections.*', 'members.name as member_name')
      .orderBy('kuri_collections.month_number')
      .orderBy('members.name');

    const payouts = await db('kuri_payouts')
      .where({ 'kuri_payouts.organization_id': orgId, 'kuri_payouts.kuri_group_id': groupId })
      .join('members', 'kuri_payouts.member_id', 'members.id')
      .select('kuri_payouts.*', 'members.name as member_name')
      .orderBy('kuri_payouts.payout_date');

    return { group, collections, payouts };
  },

  async kuriToExcel(orgId, groupId) {
    const data = await this.getKuriData(orgId, groupId);
    if (!data) return null;

    const workbook = new ExcelJS.Workbook();

    // Collections sheet
    const colSheet = workbook.addWorksheet('Collections');
    colSheet.columns = [
      { header: 'Sl No', key: 'sl', width: 8 },
      { header: 'Month', key: 'month_number', width: 10 },
      { header: 'Member', key: 'member_name', width: 25 },
      { header: 'Amount', key: 'amount', width: 12 },
      { header: 'Status', key: 'status', width: 12 },
      { header: 'Paid Date', key: 'paid_date', width: 15 },
    ];
    colSheet.getRow(1).font = { bold: true };
    colSheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE3F2FD' } };

    data.collections.forEach((c, i) => {
      colSheet.addRow({
        sl: i + 1,
        month_number: c.month_number,
        member_name: c.member_name,
        amount: parseFloat(c.amount),
        status: c.status,
        paid_date: c.paid_date ? new Date(c.paid_date).toLocaleDateString('en-IN') : '',
      });
    });

    // Payouts sheet
    const paySheet = workbook.addWorksheet('Payouts');
    paySheet.columns = [
      { header: 'Sl No', key: 'sl', width: 8 },
      { header: 'Month', key: 'month_number', width: 10 },
      { header: 'Member', key: 'member_name', width: 25 },
      { header: 'Amount', key: 'amount', width: 12 },
      { header: 'Date', key: 'payout_date', width: 15 },
    ];
    paySheet.getRow(1).font = { bold: true };
    paySheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFF3E0' } };

    data.payouts.forEach((p, i) => {
      paySheet.addRow({
        sl: i + 1,
        month_number: p.month_number,
        member_name: p.member_name,
        amount: parseFloat(p.amount),
        payout_date: p.payout_date ? new Date(p.payout_date).toLocaleDateString('en-IN') : '',
      });
    });

    return workbook.xlsx.writeBuffer();
  },

  async kuriToPdf(orgId, groupId) {
    const data = await this.getKuriData(orgId, groupId);
    if (!data) return null;
    const org = await db('organizations').where({ id: orgId }).first();

    const title = `${org.name} - Kuri Report: ${data.group.name}`;

    // Combine collections summary by month
    const monthMap = {};
    data.collections.forEach(c => {
      if (c.status === 'paid') {
        if (!monthMap[c.month_number]) monthMap[c.month_number] = { collected: 0, count: 0 };
        monthMap[c.month_number].collected += parseFloat(c.amount);
        monthMap[c.month_number].count++;
      }
    });

    const rows = Object.entries(monthMap).map(([month, info]) => {
      const payout = data.payouts.find(p => p.month_number === parseInt(month));
      return [
        month,
        String(info.count),
        `₹${info.collected.toFixed(0)}`,
        payout ? payout.member_name : '-',
        payout ? `₹${parseFloat(payout.amount).toFixed(0)}` : '-',
      ];
    });

    return this._generateTablePdf(title, {
      headers: ['Month', 'Paid', 'Collected', 'Payout To', 'Payout Amt'],
      widths: [45, 40, 80, 120, 80],
      rows,
    });
  },

  // ═══════════════════════════════════════════════════════════════
  // KANEEV REPORT
  // ═══════════════════════════════════════════════════════════════
  async getKaneevData(orgId) {
    const group = await db('kaneev_groups').where({ organization_id: orgId }).first();
    if (!group) return null;

    const donations = await db('kaneev_donations')
      .where({ 'kaneev_donations.organization_id': orgId, 'kaneev_donations.kaneev_group_id': group.id })
      .join('members', 'kaneev_donations.member_id', 'members.id')
      .select('kaneev_donations.*', 'members.name as member_name')
      .orderBy('kaneev_donations.month_number')
      .orderBy('members.name');

    const recipients = await db('kaneev_recipients')
      .where({ 'kaneev_recipients.organization_id': orgId, 'kaneev_recipients.kaneev_group_id': group.id })
      .join('members', 'kaneev_recipients.member_id', 'members.id')
      .select('kaneev_recipients.*', 'members.name as member_name')
      .orderBy('month_number');

    const balanceLogs = await db('kaneev_balance_log')
      .where({ organization_id: orgId, kaneev_group_id: group.id })
      .orderBy('month_number');

    return { group, donations, recipients, balanceLogs };
  },

  async kaneevToExcel(orgId) {
    const data = await this.getKaneevData(orgId);
    if (!data) return null;

    const workbook = new ExcelJS.Workbook();

    // Donations sheet
    const donSheet = workbook.addWorksheet('Donations');
    donSheet.columns = [
      { header: 'Sl No', key: 'sl', width: 8 },
      { header: 'Month', key: 'month_number', width: 10 },
      { header: 'Member', key: 'member_name', width: 25 },
      { header: 'Amount', key: 'amount', width: 12 },
      { header: 'Status', key: 'status', width: 12 },
      { header: 'Paid Date', key: 'paid_date', width: 15 },
    ];
    donSheet.getRow(1).font = { bold: true };
    data.donations.forEach((d, i) => {
      donSheet.addRow({
        sl: i + 1,
        month_number: d.month_number,
        member_name: d.member_name,
        amount: parseFloat(d.amount),
        status: d.status,
        paid_date: d.paid_date ? new Date(d.paid_date).toLocaleDateString('en-IN') : '',
      });
    });

    // Recipients sheet
    const recSheet = workbook.addWorksheet('Recipients');
    recSheet.columns = [
      { header: 'Month', key: 'month_number', width: 10 },
      { header: 'Recipient', key: 'member_name', width: 25 },
      { header: 'Amount', key: 'total_amount', width: 12 },
      { header: 'Date', key: 'received_date', width: 15 },
    ];
    recSheet.getRow(1).font = { bold: true };
    data.recipients.forEach(r => {
      recSheet.addRow({
        month_number: r.month_number,
        member_name: r.member_name,
        total_amount: parseFloat(r.total_amount),
        received_date: r.received_date ? new Date(r.received_date).toLocaleDateString('en-IN') : '',
      });
    });

    // Balance sheet
    const balSheet = workbook.addWorksheet('Balance');
    balSheet.columns = [
      { header: 'Month', key: 'month_number', width: 10 },
      { header: 'Collected', key: 'total_collected', width: 14 },
      { header: 'Distributed', key: 'total_distributed', width: 14 },
      { header: 'Month Balance', key: 'month_balance', width: 14 },
      { header: 'Cumulative', key: 'cumulative_balance', width: 14 },
    ];
    balSheet.getRow(1).font = { bold: true };
    data.balanceLogs.forEach(b => {
      balSheet.addRow({
        month_number: b.month_number,
        total_collected: parseFloat(b.total_collected),
        total_distributed: parseFloat(b.total_distributed),
        month_balance: parseFloat(b.month_balance),
        cumulative_balance: parseFloat(b.cumulative_balance),
      });
    });

    return workbook.xlsx.writeBuffer();
  },

  async kaneevToPdf(orgId) {
    const data = await this.getKaneevData(orgId);
    if (!data) return null;
    const org = await db('organizations').where({ id: orgId }).first();

    const title = `${org.name} - കനീവ് Report`;
    const rows = data.balanceLogs.map(b => [
      String(b.month_number),
      `₹${parseFloat(b.total_collected).toFixed(0)}`,
      `₹${parseFloat(b.total_distributed).toFixed(0)}`,
      `₹${parseFloat(b.month_balance).toFixed(0)}`,
      `₹${parseFloat(b.cumulative_balance).toFixed(0)}`,
    ]);

    return this._generateTablePdf(title, {
      headers: ['Month', 'Collected', 'Distributed', 'Month Bal', 'Cumulative'],
      widths: [50, 80, 80, 80, 80],
      rows,
    });
  },

  // ═══════════════════════════════════════════════════════════════
  // FINANCE REPORT (Balance Sheet)
  // ═══════════════════════════════════════════════════════════════
  async getFinanceData(orgId, { fromDate, toDate } = {}) {
    let query = db('finance_transactions as ft')
      .join('finance_categories as fc', 'ft.category_id', 'fc.id')
      .where({ 'ft.organization_id': orgId })
      .select('ft.*', 'fc.name as category_name');

    if (fromDate) query = query.andWhere('ft.date', '>=', fromDate);
    if (toDate) query = query.andWhere('ft.date', '<=', toDate);

    const transactions = await query.orderBy('ft.date', 'desc');

    const summary = await db('finance_transactions')
      .where({ organization_id: orgId })
      .select('type')
      .sum('amount as total')
      .groupBy('type');

    let income = 0, expense = 0;
    summary.forEach(s => {
      if (s.type === 'income') income = parseFloat(s.total);
      if (s.type === 'expense') expense = parseFloat(s.total);
    });

    return { transactions, income, expense, balance: income - expense };
  },

  async financeToExcel(orgId, { fromDate, toDate } = {}) {
    const data = await this.getFinanceData(orgId, { fromDate, toDate });
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Finance');

    sheet.columns = [
      { header: 'Sl No', key: 'sl', width: 8 },
      { header: 'Date', key: 'date', width: 14 },
      { header: 'Type', key: 'type', width: 10 },
      { header: 'Category', key: 'category_name', width: 20 },
      { header: 'Description', key: 'description', width: 30 },
      { header: 'Amount', key: 'amount', width: 12 },
    ];
    sheet.getRow(1).font = { bold: true };
    sheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFCE4EC' } };

    data.transactions.forEach((t, i) => {
      sheet.addRow({
        sl: i + 1,
        date: t.date ? new Date(t.date).toLocaleDateString('en-IN') : '',
        type: t.type,
        category_name: t.category_name,
        description: t.description || '',
        amount: parseFloat(t.amount),
      });
    });

    // Summary row
    sheet.addRow({});
    const summaryRow = sheet.addRow({ sl: '', date: '', type: '', category_name: 'SUMMARY', description: '', amount: '' });
    summaryRow.font = { bold: true };
    sheet.addRow({ sl: '', date: '', type: '', category_name: 'Total Income', description: '', amount: data.income });
    sheet.addRow({ sl: '', date: '', type: '', category_name: 'Total Expense', description: '', amount: data.expense });
    const balRow = sheet.addRow({ sl: '', date: '', type: '', category_name: 'Balance', description: '', amount: data.balance });
    balRow.font = { bold: true };

    return workbook.xlsx.writeBuffer();
  },

  async financeToPdf(orgId, { fromDate, toDate } = {}) {
    const data = await this.getFinanceData(orgId, { fromDate, toDate });
    const org = await db('organizations').where({ id: orgId }).first();

    const title = `${org.name} - Finance Report`;

    const rows = data.transactions.slice(0, 100).map((t, i) => [
      String(i + 1),
      t.date ? new Date(t.date).toLocaleDateString('en-IN') : '',
      t.type,
      t.category_name,
      `₹${parseFloat(t.amount).toFixed(0)}`,
    ]);

    // Add summary
    rows.push(['', '', '', '', '']);
    rows.push(['', '', '', 'Total Income', `₹${data.income.toFixed(0)}`]);
    rows.push(['', '', '', 'Total Expense', `₹${data.expense.toFixed(0)}`]);
    rows.push(['', '', '', 'Balance', `₹${data.balance.toFixed(0)}`]);

    return this._generateTablePdf(title, {
      headers: ['#', 'Date', 'Type', 'Category', 'Amount'],
      widths: [25, 70, 55, 120, 70],
      rows,
    });
  },

  // ═══════════════════════════════════════════════════════════════
  // PDF HELPER — Simple table-based PDF
  // ═══════════════════════════════════════════════════════════════
  _generateTablePdf(title, { headers, widths, rows }) {
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ size: 'A4', margin: 40 });
      const chunks = [];
      doc.on('data', chunk => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // Title
      doc.fontSize(14).font('Helvetica-Bold').text(title, { align: 'center' });
      doc.moveDown(0.5);
      doc.fontSize(9).font('Helvetica').text(`Generated: ${new Date().toLocaleDateString('en-IN')}`, { align: 'right' });
      doc.moveDown(1);

      const startX = 40;
      const rowHeight = 20;
      let y = doc.y;

      // Header row
      doc.font('Helvetica-Bold').fontSize(9);
      let x = startX;
      headers.forEach((h, i) => {
        doc.text(h, x, y, { width: widths[i], align: 'left' });
        x += widths[i];
      });
      y += rowHeight;

      // Draw line under header
      doc.moveTo(startX, y - 5).lineTo(startX + widths.reduce((a, b) => a + b, 0), y - 5).stroke();

      // Data rows
      doc.font('Helvetica').fontSize(8);
      rows.forEach(row => {
        if (y > 750) {
          doc.addPage();
          y = 40;
        }
        x = startX;
        row.forEach((cell, i) => {
          doc.text(cell || '', x, y, { width: widths[i], align: 'left' });
          x += widths[i];
        });
        y += rowHeight;
      });

      doc.end();
    });
  },
};

module.exports = exportService;
