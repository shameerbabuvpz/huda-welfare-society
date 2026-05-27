import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton for list screens that show Card > ListTile items
class ListSkeletonLoader extends StatelessWidget {
  final int itemCount;
  final bool hasLeadingAvatar;
  final bool hasTrailingBadge;

  const ListSkeletonLoader({
    super.key,
    this.itemCount = 6,
    this.hasLeadingAvatar = true,
    this.hasTrailingBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: itemCount,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: hasLeadingAvatar
                ? const CircleAvatar(child: Icon(Icons.person))
                : null,
            title: Text(BoneMock.name),
            subtitle: Text(BoneMock.subtitle),
            trailing: hasTrailingBadge
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Status'),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Skeleton for dashboard-style screens with cards and sections
class DashboardSkeletonLoader extends StatelessWidget {
  const DashboardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          // Header actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(
              3,
              (_) => Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.grey.shade200,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Banner placeholder
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          // Card placeholder
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
          // Section title
          Text(BoneMock.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(BoneMock.subtitle, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 16),
          // Service items
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(BoneMock.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(BoneMock.subtitle, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for detail screens
class DetailSkeletonLoader extends StatelessWidget {
  const DetailSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(BoneMock.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(BoneMock.paragraph),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Status'),
                      ),
                      const Spacer(),
                      Text(BoneMock.date),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Info rows
          ...List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(BoneMock.words(2), style: const TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text(BoneMock.words(3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for grid/stats screens
class GridSkeletonLoader extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;

  const GridSkeletonLoader({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(BoneMock.name, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Text(BoneMock.words(1), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
