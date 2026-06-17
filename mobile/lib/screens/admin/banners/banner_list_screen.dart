import 'dart:typed_data';

import 'package:ayalkoottam/widgets/skeleton_loaders.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../models/banner.dart' as app;
import '../../../providers/banner_provider.dart';
import '../../../widgets/app_bottom_sheet.dart';

class BannerListScreen extends StatefulWidget {
  const BannerListScreen({super.key});

  @override
  State<BannerListScreen> createState() => _BannerListScreenState();
}

class _BannerListScreenState extends State<BannerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BannerProvider>().loadBanners();
    });
  }

  Future<void> _addBanner() async {
    final titleCtrl = TextEditingController();
    final sortCtrl = TextEditingController(text: '0');
    Uint8List? imageBytes;
    String? imageFilename;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showAppSheet<bool>(
      context: context,
      title: 'Add Banner',
      initialChildSize: 0.5,
      body: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sortCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sort Order'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, imageQuality: 70);
                  if (file != null) {
                    final bytes = await file.readAsBytes();
                    setSheetState(() {
                      imageBytes = bytes;
                      imageFilename = file.name;
                    });
                  }
                },
                icon: const Icon(Icons.image),
                label: Text(imageBytes != null ? 'Image selected' : 'Select Banner Image'),
              ),
            ],
          );
        },
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Add'),
        ),
      ],
    );

    if (result == true && mounted) {
      if (titleCtrl.text.trim().isEmpty || imageBytes == null) {
        scaffoldMessenger.showSnackBar(AppTheme.errorSnackBar('Title and image are required'));
        return;
      }
      final success = await context.read<BannerProvider>().createBanner(
            title: titleCtrl.text.trim(),
            imageBytes: imageBytes!,
            imageFilename: imageFilename,
            sortOrder: int.tryParse(sortCtrl.text) ?? 0,
          );
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        success ? AppTheme.successSnackBar('Banner added') : AppTheme.errorSnackBar('Failed to add banner'),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      titleCtrl.dispose();
      sortCtrl.dispose();
    });
  }

  Future<void> _editBanner(app.Banner banner) async {
    final titleCtrl = TextEditingController(text: banner.title);
    final sortCtrl = TextEditingController(text: banner.sortOrder.toString());
    Uint8List? imageBytes;
    String? imageFilename;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showAppSheet<bool>(
      context: context,
      title: 'Edit Banner',
      initialChildSize: 0.5,
      body: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sortCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sort Order'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, imageQuality: 70);
                  if (file != null) {
                    final bytes = await file.readAsBytes();
                    setSheetState(() {
                      imageBytes = bytes;
                      imageFilename = file.name;
                    });
                  }
                },
                icon: const Icon(Icons.image),
                label: Text(imageBytes != null ? 'New image selected' : 'Change Image (optional)'),
              ),
            ],
          );
        },
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Save'),
        ),
      ],
    );

    if (result == true && mounted) {
      final success = await context.read<BannerProvider>().updateBanner(
            banner.id,
            title: titleCtrl.text.trim(),
            imageBytes: imageBytes,
            imageFilename: imageFilename,
            sortOrder: int.tryParse(sortCtrl.text) ?? banner.sortOrder,
          );
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        success ? AppTheme.successSnackBar('Banner updated') : AppTheme.errorSnackBar('Update failed'),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      titleCtrl.dispose();
      sortCtrl.dispose();
    });
  }

  Future<void> _deleteBanner(app.Banner banner) async {
    final provider = context.read<BannerProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirm = await showConfirmSheet(
      context: context,
      title: 'Delete Banner',
      message: 'Delete "${banner.title}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirm == true && mounted) {
      final success = await provider.deleteBanner(banner.id);
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        success ? AppTheme.successSnackBar('Banner deleted') : AppTheme.errorSnackBar('Delete failed'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BannerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Banners'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addBanner),
        ],
      ),
      body: provider.loading
          ? const ListSkeletonLoader()
          : provider.banners.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No banners yet', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _addBanner,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Banner'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<BannerProvider>().loadBanners(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.banners.length,
                    itemBuilder: (ctx, i) {
                      final banner = provider.banners[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 6,
                              child: CachedNetworkImage(
                                imageUrl: banner.imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image, size: 40),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          banner.title,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                        Text(
                                          banner.isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: banner.isActive ? AppTheme.success : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _editBanner(banner),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: AppTheme.error),
                                    onPressed: () => _deleteBanner(banner),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
