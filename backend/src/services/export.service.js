const ExcelJS = require('exceljs');
const PDFDocument = require('pdfkit');
const path = require('path');
const db = require('../config/database');
const ayalkoottamService = require('./ayalkoottam.service');

// Unicode font (Latin + Malayalam) so report titles/data with Malayalam render
// correctly. PDFKit's built-in Helvetica cannot draw Malayalam glyphs.
const FONT_REGULAR = path.join(__dirname, '../assets/fonts/NotoSansMalayalam-Regular.ttf');
const FONT_BOLD = path.join(__dirname, '../assets/fonts/NotoSansMalayalam-Bold.ttf');

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

    // Per-member summary: join date + total amount paid
    const paidTotals = await db('kaneev_donations')
      .where({ kaneev_group_id: group.id, organization_id: orgId, status: 'paid' })
      .groupBy('member_id')
      .select('member_id')
      .sum('amount as total_paid');
    const paidMap = {};
    paidTotals.forEach((row) => { paidMap[row.member_id] = parseFloat(row.total_paid) || 0; });

    const memberRows = await db('kaneev_members')
      .where({ 'kaneev_members.kaneev_group_id': group.id, 'kaneev_members.organization_id': orgId })
      .join('members', 'kaneev_members.member_id', 'members.id')
      .leftJoin('ayalkoottams', 'members.ayalkoottam_id', 'ayalkoottams.id')
      .select(
        'kaneev_members.member_id',
        'kaneev_members.status',
        'kaneev_members.slot_number',
        'kaneev_members.created_at as joined_date',
        'members.name as member_name',
        'members.member_code',
        'ayalkoottams.name as ayalkoottam_name',
      )
      .orderBy('kaneev_members.slot_number');

    const memberSummary = memberRows.map((m) => ({
      ...m,
      total_paid: paidMap[m.member_id] || 0,
    }));

    return { group, donations, recipients, balanceLogs, memberSummary };
  },

  async kaneevToExcel(orgId) {
    const data = await this.getKaneevData(orgId);
    if (!data) return null;

    const workbook = new ExcelJS.Workbook();

    // Member Totals sheet — total amount paid by each member + join date
    const memSheet = workbook.addWorksheet('Member Totals');
    memSheet.columns = [
      { header: 'Sl No', key: 'sl', width: 8 },
      { header: 'Slot', key: 'slot', width: 8 },
      { header: 'Member', key: 'member_name', width: 25 },
      { header: 'Code', key: 'member_code', width: 16 },
      { header: 'Ayalkoottam', key: 'ayalkoottam_name', width: 20 },
      { header: 'Joined Date', key: 'joined_date', width: 15 },
      { header: 'Total Paid', key: 'total_paid', width: 14 },
      { header: 'Status', key: 'status', width: 12 },
    ];
    memSheet.getRow(1).font = { bold: true };
    let grandTotalPaid = 0;
    (data.memberSummary || []).forEach((m, i) => {
      grandTotalPaid += parseFloat(m.total_paid) || 0;
      memSheet.addRow({
        sl: i + 1,
        slot: m.slot_number ?? '',
        member_name: m.member_name,
        member_code: m.member_code || '',
        ayalkoottam_name: m.ayalkoottam_name || '',
        joined_date: m.joined_date ? new Date(m.joined_date).toLocaleDateString('en-IN') : '',
        total_paid: parseFloat(m.total_paid) || 0,
        status: m.status === 'active' ? 'Active' : 'Inactive',
      });
    });
    const totalRow = memSheet.addRow({ member_name: 'TOTAL', total_paid: grandTotalPaid });
    totalRow.font = { bold: true };

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

    const title = `${org.name} - കനീവ് Member Totals`;
    let grandTotal = 0;
    const rows = (data.memberSummary || []).map((m, i) => {
      grandTotal += parseFloat(m.total_paid) || 0;
      return [
        String(i + 1),
        m.member_name || '',
        m.joined_date ? new Date(m.joined_date).toLocaleDateString('en-IN') : '',
        `₹${(parseFloat(m.total_paid) || 0).toFixed(0)}`,
        m.status === 'active' ? 'Active' : 'Inactive',
      ];
    });
    rows.push(['', 'TOTAL', '', `₹${grandTotal.toFixed(0)}`, '']);

    return this._generateTablePdf(title, {
      headers: ['Sl', 'Member', 'Joined', 'Total Paid', 'Status'],
      widths: [30, 170, 80, 90, 70],
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
  // OFFICE-BEARERS (PRESIDENT / SECRETARY) REPORT
  // ═══════════════════════════════════════════════════════════════
  async leadersToExcel(orgId) {
    const rows = await ayalkoottamService.getLeaders(orgId);
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Office Bearers');

    sheet.columns = [
      { header: 'Sl No', key: 'sl', width: 8 },
      { header: 'Ayalkoottam', key: 'ayalkoottam_name', width: 28 },
      { header: 'President Name', key: 'president_name', width: 22 },
      { header: 'President ID', key: 'president_code', width: 18 },
      { header: 'President Mobile', key: 'president_phone', width: 16 },
      { header: 'Secretary Name', key: 'secretary_name', width: 22 },
      { header: 'Secretary ID', key: 'secretary_code', width: 18 },
      { header: 'Secretary Mobile', key: 'secretary_phone', width: 16 },
    ];

    sheet.getRow(1).font = { bold: true };
    sheet.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE8F5E9' } };

    rows.forEach((r, i) => {
      sheet.addRow({
        sl: i + 1,
        ayalkoottam_name: r.ayalkoottam_name,
        president_name: r.president_name,
        president_code: r.president_code,
        president_phone: r.president_phone,
        secretary_name: r.secretary_name,
        secretary_code: r.secretary_code,
        secretary_phone: r.secretary_phone,
      });
    });

    return workbook.xlsx.writeBuffer();
  },

  async leadersToPdf(orgId) {
    const rows = await ayalkoottamService.getLeaders(orgId);
    const org = await db('organizations').where({ id: orgId }).first();
    const title = `${org.name} - Office Bearers (President / Secretary)`;

    return this._generateTablePdf(title, {
      headers: ['#', 'Ayalkoottam', 'President', 'Pres. ID', 'Pres. Mobile', 'Secretary', 'Sec. ID', 'Sec. Mobile'],
      widths: [18, 110, 80, 70, 75, 80, 70, 75],
      landscape: true,
      rows: rows.map((r, i) => [
        String(i + 1),
        r.ayalkoottam_name || '',
        r.president_name || '',
        r.president_code || '',
        r.president_phone || '',
        r.secretary_name || '',
        r.secretary_code || '',
        r.secretary_phone || '',
      ]),
    });
  },

  // ═══════════════════════════════════════════════════════════════
  // PDF HELPER — Simple table-based PDF
  // ═══════════════════════════════════════════════════════════════
  _generateTablePdf(title, { headers, widths, rows, landscape = false }) {
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ size: 'A4', margin: 40, layout: landscape ? 'landscape' : 'portrait' });
      const chunks = [];
      doc.on('data', chunk => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // Register a Unicode font (Malayalam + ₹) used only for the runs Helvetica
      // cannot draw. Helvetica stays the default for Latin text. The Malayalam
      // Noto font has no Latin letters, so we must switch fonts per script run.
      let haveUni = false;
      try {
        doc.registerFont('Mal', FONT_REGULAR);
        doc.registerFont('MalBold', FONT_BOLD);
        haveUni = true;
      } catch (e) {
        // keep Helvetica-only fallback
      }

      // A char needs the Unicode font if Helvetica (WinAnsi) cannot render it:
      // Malayalam block or the ₹ rupee sign.
      const needsUni = (cp) => haveUni && ((cp >= 0x0d00 && cp <= 0x0d7f) || cp === 0x20b9);
      const segment = (text) => {
        const segs = [];
        let cur = '';
        let curUni = null;
        for (const ch of String(text)) {
          const u = needsUni(ch.codePointAt(0));
          if (curUni === null) { curUni = u; cur = ch; }
          else if (u === curUni) { cur += ch; }
          else { segs.push({ text: cur, uni: curUni }); cur = ch; curUni = u; }
        }
        if (cur !== '' || segs.length === 0) segs.push({ text: cur, uni: curUni || false });
        return segs;
      };
      // Draw text that may mix Latin and Malayalam/₹ by switching fonts between
      // runs using PDFKit's `continued` chaining. `bold` picks the bold variants.
      const richText = (text, x, y, opts, bold) => {
        const latin = bold ? 'Helvetica-Bold' : 'Helvetica';
        const uni = bold ? 'MalBold' : 'Mal';
        const segs = segment(text);
        segs.forEach((s, i) => {
          doc.font(s.uni ? uni : latin);
          const o = { ...opts, continued: i < segs.length - 1 };
          if (i === 0 && x != null) doc.text(s.text, x, y, o);
          else doc.text(s.text, o);
        });
      };

      // Bottom threshold for page breaks (A4: 842pt portrait / 595pt landscape height).
      const pageBottom = (landscape ? 595 : 842) - 50;

      // Title
      doc.fontSize(14);
      richText(title, null, null, { align: 'center' }, true);
      doc.moveDown(0.5);
      doc.fontSize(9).font('Helvetica').text(`Generated: ${new Date().toLocaleDateString('en-IN')}`, { align: 'right' });
      doc.moveDown(1);

      const startX = 40;
      const rowHeight = 20;
      let y = doc.y;

      // Cell padding inside each column and gap below each row.
      const cellPadX = 4;
      const rowGap = 6;

      // Measure the rendered height of a cell, accounting for wrapping at the
      // column width. Because a cell may mix Latin (Helvetica) and Malayalam
      // (Noto) which have different metrics, measure with both and take the max
      // so wrapped rows never overlap.
      const cellHeight = (text, width, bold) => {
        const w = Math.max(1, width - cellPadX);
        doc.font(bold ? 'Helvetica-Bold' : 'Helvetica');
        let h = doc.heightOfString(String(text || ''), { width: w });
        if (haveUni) {
          doc.font(bold ? 'MalBold' : 'Mal');
          h = Math.max(h, doc.heightOfString(String(text || ''), { width: w }));
        }
        return h;
      };

      // Header row
      doc.fontSize(9);
      let x = startX;
      const headerH = Math.max(rowHeight, ...headers.map((h, i) => cellHeight(h, widths[i], true)) ) + rowGap;
      headers.forEach((h, i) => {
        richText(h, x, y, { width: widths[i] - cellPadX, align: 'left' }, true);
        x += widths[i];
      });
      y += headerH;

      // Draw line under header
      doc.moveTo(startX, y - 5).lineTo(startX + widths.reduce((a, b) => a + b, 0), y - 5).stroke();

      // Data rows
      doc.fontSize(8);
      rows.forEach(row => {
        // Tallest cell decides the row height so wrapped text never overlaps.
        const rowH = Math.max(rowHeight, ...row.map((cell, i) => cellHeight(cell, widths[i], false))) + rowGap;
        if (y + rowH > pageBottom) {
          doc.addPage();
          y = 40;
        }
        x = startX;
        row.forEach((cell, i) => {
          richText(cell || '', x, y, { width: widths[i] - cellPadX, align: 'left' }, false);
          x += widths[i];
        });
        y += rowH;
      });

      doc.end();
    });
  },
};

module.exports = exportService;
