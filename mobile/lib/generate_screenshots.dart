import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';

/// Generate store listing screenshots as PNG files
/// Run: cd mobile && flutter run -d macos -t lib/generate_screenshots.dart

void main() {
  runApp(const ScreenshotApp());
}

class ScreenshotApp extends StatelessWidget {
  const ScreenshotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B5E20),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const ScreenshotGallery(),
    );
  }
}

class ScreenshotGallery extends StatefulWidget {
  const ScreenshotGallery({super.key});

  @override
  State<ScreenshotGallery> createState() => _ScreenshotGalleryState();
}

class _ScreenshotGalleryState extends State<ScreenshotGallery> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _MockDashboard(),
    const _MockMemberList(),
    const _MockPrivilegeCard(),
    const _MockKuri(),
    const _MockKaneev(),
    const _MockAssets(),
    const _MockNotifications(),
    const _MockReports(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Members',
    'Privilege Card',
    'Kuri',
    'Kaneev',
    'Assets',
    'Notifications',
    'Reports',
  ];

  @override
  Widget build(BuildContext context) {
    // Render the mock screen directly (no phone frame) for clean screenshots
    return Stack(
      children: [
        _screens[_currentIndex],
        // Navigation overlay at very bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                ),
                Text('${_currentIndex + 1}/8: ${_titles[_currentIndex]}',
                    style: const TextStyle(color: Colors.white, fontSize: 14, decoration: TextDecoration.none)),
                GestureDetector(
                  onTap: _currentIndex < 7 ? () => setState(() => _currentIndex++) : null,
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// MOCK SCREENS FOR SCREENSHOTS
// ═══════════════════════════════════════════════

const _primary = Color(0xFF1B5E20);
const _primaryLight = Color(0xFF4CAF50);
const _surface = Color(0xFFFAFAFA);
const _accent = Color(0xFFFFC107);

class _MockDashboard extends StatelessWidget {
  const _MockDashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.groups, color: _primary, size: 24),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ayalkoottam', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Ward 5 - Neighbourhood Group', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: null),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats cards
          Row(
            children: [
              _statCard('Members', '47', Icons.people, _primary),
              const SizedBox(width: 12),
              _statCard('Kuri Groups', '3', Icons.savings, Colors.orange.shade700),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard('Assets', '12', Icons.inventory_2, Colors.blue.shade700),
              const SizedBox(width: 12),
              _statCard('Kaneev', '₹4,700', Icons.volunteer_activism, Colors.purple.shade700),
            ],
          ),
          const SizedBox(height: 20),
          // Quick actions
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _actionChip(Icons.person_add, 'Add Member'),
              _actionChip(Icons.payments, 'Collect Kuri'),
              _actionChip(Icons.volunteer_activism, 'Record Kaneev'),
              _actionChip(Icons.campaign, 'Send Notice'),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _activityTile('Rajan P', 'Kuri payment received - ₹500', '2 hrs ago'),
          _activityTile('Suresh K', 'Asset returned - Book Set', '5 hrs ago'),
          _activityTile('Latha M', 'Kaneev recipient selected', 'Yesterday'),
        ],
      ),
    );
  }

  static Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  static Widget _actionChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: _primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, color: _primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static Widget _activityTile(String name, String action, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: _primary.withOpacity(0.1), child: Text(name[0], style: const TextStyle(color: _primary))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(action, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(time, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _MockMemberList extends StatelessWidget {
  const _MockMemberList();

  @override
  Widget build(BuildContext context) {
    final members = [
      ('Rajan Pillai', 'AK-01', 'Ward 5 Koottam'),
      ('Suresh Kumar', 'AK-02', 'Ward 5 Koottam'),
      ('Latha Menon', 'AK-03', 'Ward 7 Koottam'),
      ('Anil Das', 'AK-04', 'Ward 5 Koottam'),
      ('Priya Nair', 'AK-05', 'Ward 7 Koottam'),
      ('Manoj V', 'AK-06', 'Ward 9 Koottam'),
      ('Deepa S', 'AK-07', 'Ward 5 Koottam'),
      ('Vinod P', 'AK-08', 'Ward 9 Koottam'),
    ];

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Members'),
        actions: [IconButton(icon: const Icon(Icons.person_add), onPressed: null)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (ctx, i) {
                final (name, code, ak) = members[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _primary.withOpacity(0.1),
                    child: Text(name[0], style: const TextStyle(color: _primary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('$code • $ak', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MockPrivilegeCard extends StatelessWidget {
  const _MockPrivilegeCard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Privilege Card'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.groups, color: _primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('AYALKOOTTAM', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_2, size: 90, color: _primary),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('RAJAN PILLAI', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Member ID: AK-001', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                const SizedBox(height: 4),
                Text('Ward 5 Neighbourhood Group', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('ACTIVE MEMBER', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MockKuri extends StatelessWidget {
  const _MockKuri();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Kuri - Group A'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_primary, Color(0xFF2E7D32)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Monthly Kuri', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('₹500/month', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _kuriStat('Members', '20'),
                    _kuriStat('Duration', '20 mo'),
                    _kuriStat('Collected', '₹8,500'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Month 6 Collection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('15/20 paid', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 12),
          // Collection grid
          ...List.generate(6, (i) {
            final paid = i < 4;
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: paid ? _primary.withOpacity(0.1) : Colors.grey.shade200,
                child: Icon(paid ? Icons.check : Icons.close, size: 16, color: paid ? _primary : Colors.grey),
              ),
              title: Text(['Rajan P', 'Suresh K', 'Latha M', 'Anil D', 'Priya N', 'Manoj V'][i],
                  style: const TextStyle(fontSize: 14)),
              trailing: Text(paid ? 'Paid ✓' : 'Pending',
                  style: TextStyle(fontSize: 12, color: paid ? _primary : Colors.orange, fontWeight: FontWeight.w600)),
            );
          }),
        ],
      ),
    );
  }

  static Widget _kuriStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _MockKaneev extends StatelessWidget {
  const _MockKaneev();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Kaneev (കനീവ്)'),
      ),
      body: Column(
        children: [
          // Balance header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_primary, Color(0xFF388E3C)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text('Current Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(height: 4),
                Text('₹4,700', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('₹100/member/month', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _chip('All', true),
                const SizedBox(width: 8),
                _chip('Unpaid', false),
                const SizedBox(width: 8),
                _chip('Paid', false),
                const Spacer(),
                Text('Month 6', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const Divider(height: 20),
          Expanded(
            child: ListView(
              children: [
                _kaneevMember('Rajan P', 'Ward 5', true),
                _kaneevMember('Suresh K', 'Ward 5', true),
                _kaneevMember('Latha M', 'Ward 7', true),
                _kaneevMember('Anil D', 'Ward 5', false),
                _kaneevMember('Priya N', 'Ward 7', false),
                _kaneevMember('Manoj V', 'Ward 9', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _chip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? _primary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? _primary : Colors.grey.shade400),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.grey.shade700)),
    );
  }

  static Widget _kaneevMember(String name, String ward, bool paid) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: paid ? _primary.withOpacity(0.1) : Colors.grey.shade200,
            child: paid
                ? const Icon(Icons.check, size: 16, color: _primary)
                : Text(name[0], style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(ward, style: const TextStyle(fontSize: 11, color: _primaryLight)),
              ],
            ),
          ),
          if (paid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Text('Paid ✓', style: TextStyle(fontSize: 11, color: _primary, fontWeight: FontWeight.w600)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(8)),
              child: const Text('₹ Pay', style: TextStyle(fontSize: 11, color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

class _MockAssets extends StatelessWidget {
  const _MockAssets();

  @override
  Widget build(BuildContext context) {
    final assets = [
      ('Library Book Set', 'Rajan P', 'Issued', Icons.menu_book),
      ('Folding Table', 'Available', 'Available', Icons.table_bar),
      ('Sound System', 'Suresh K', 'Issued', Icons.speaker),
      ('Tent Set', 'Latha M', 'Overdue', Icons.foundation),
      ('Cooking Vessels', 'Available', 'Available', Icons.soup_kitchen),
      ('Chairs (20)', 'Anil D', 'Issued', Icons.chair),
    ];

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Assets'),
        actions: [IconButton(icon: const Icon(Icons.add_box), onPressed: null)],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: assets.length,
        itemBuilder: (ctx, i) {
          final (name, assignee, status, icon) = assets[i];
          Color statusColor;
          if (status == 'Available') {
            statusColor = _primary;
          } else if (status == 'Overdue') {
            statusColor = Colors.red;
          } else {
            statusColor = Colors.orange.shade700;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _primary, size: 22),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(assignee, style: const TextStyle(fontSize: 12)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MockNotifications extends StatelessWidget {
  const _MockNotifications();

  @override
  Widget build(BuildContext context) {
    final notifications = [
      ('Meeting Tomorrow', 'Monthly meeting at community hall, 6 PM', '2 hrs ago', Icons.event),
      ('Kuri Collection', 'Month 6 kuri collection started. Please pay ₹500', '1 day ago', Icons.payments),
      ('New Member', 'Deepa S joined the group. Welcome!', '2 days ago', Icons.person_add),
      ('Asset Return', 'Please return "Library Book Set" by May 30', '3 days ago', Icons.inventory),
      ('Kaneev Update', 'Latha M selected as recipient for May', '4 days ago', Icons.volunteer_activism),
    ];

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Notifications'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        itemBuilder: (ctx, i) {
          final (title, body, time, icon) = notifications[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(body, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        const SizedBox(height: 6),
                        Text(time, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MockReports extends StatelessWidget {
  const _MockReports();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Reports & Export'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _reportCard('Member Report', 'All members with contact details', Icons.people, '47 members'),
          _reportCard('Kuri Financial', 'Collection & payout ledger', Icons.savings, '3 groups'),
          _reportCard('Kaneev Summary', 'Monthly donations & recipients', Icons.volunteer_activism, '18 months'),
          _reportCard('Asset Register', 'All assets with status', Icons.inventory_2, '12 assets'),
          _reportCard('Due Report', 'Overdue & pending payments', Icons.warning_amber, '5 overdue'),
          const SizedBox(height: 20),
          const Text('Export Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primary.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.table_chart, color: _primary, size: 28),
                      SizedBox(height: 8),
                      Text('CSV', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                      SizedBox(height: 8),
                      Text('PDF', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _reportCard(String title, String desc, IconData icon, String badge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(badge, style: const TextStyle(fontSize: 11, color: _primary, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
