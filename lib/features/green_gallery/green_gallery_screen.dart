import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class GreenGalleryScreen extends StatefulWidget {
  const GreenGalleryScreen({Key? key}) : super(key: key);

  @override
  State<GreenGalleryScreen> createState() => _GreenGalleryScreenState();
}

class _GreenGalleryScreenState extends State<GreenGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, List<String>> _categoryAssets = {
    'Indoor': [],
    'Medicinal': [],
    'Outdoor': [],
  };
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categoryAssets.keys.length, vsync: this);
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      for (final entry in manifestMap.entries) {
        final String assetPath = entry.key;
        if (!assetPath.startsWith('assets/images/')) continue;
        final parts = assetPath.split('/');
        if (parts.length < 4) continue; // ignore files directly under images
        final category = parts[2]; // folder name
        final formatted = _formatCategoryName(category);
        if (_categoryAssets.containsKey(formatted)) {
          _categoryAssets[formatted]!.add(assetPath);
        }
      }
    } catch (e) {
      _error = 'Failed to load assets: $e';
    }
    setState(() {
      _loading = false;
    });
  }

  String _formatCategoryName(String raw) {
    switch (raw.toLowerCase()) {
      case 'indoor':
        return 'Indoor';
      case 'medicinal':
        return 'Medicinal';
      case 'outdoor':
        return 'Outdoor';
      default:
        return raw;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Green Gallery'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _categoryAssets.keys.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tabController,
                  children: _categoryAssets.entries.map((entry) {
                    final images = entry.value;
                    if (images.isEmpty) {
                      return Center(child: Text('No images in ${entry.key}'));
                    }
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          final asset = images[index];
                          final filename = asset.split('/').last;
                          final displayName = filename
                              .replaceAll('_', ' ')
                              .replaceAll('.png', '')
                              .replaceAll('.jpg', '')
                              .replaceAll('.jpeg', '')
                              .trim();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    asset,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Center(child: Icon(Icons.broken_image)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayName,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
