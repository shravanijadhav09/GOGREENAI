import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/owner_provider.dart';
import 'models/gallery_image.dart';

class OurPlantGalleryScreen extends StatefulWidget {
  const OurPlantGalleryScreen({super.key});

  @override
  State<OurPlantGalleryScreen> createState() => _OurPlantGalleryScreenState();
}

class _OurPlantGalleryScreenState extends State<OurPlantGalleryScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().fetchGallery(refresh: true);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (picked == null || !mounted) return;

      final file = File(picked.path);
      final details = await _showPhotoDetailsDialog();
      if (details == null || !mounted) return;

      final provider = context.read<OwnerProvider>();
      final success = await provider.uploadGalleryImage(
        file: file,
        caption: details['caption'],
        category: details['category'],
      );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo added to nursery gallery!'),
            backgroundColor: AppColors.botanicalGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.galleryError ?? 'Failed to upload photo.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not access camera or file: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final pickedList = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedList.isEmpty || !mounted) return;

      final files = pickedList.map((x) => File(x.path)).toList();
      final details = await _showCategorySelectionDialog();
      if (details == null || !mounted) return;

      final provider = context.read<OwnerProvider>();
      final count = await provider.uploadMultipleGalleryImages(
        files: files,
        category: details,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count of ${files.length} photos uploaded to your gallery!'),
          backgroundColor: count > 0 ? AppColors.botanicalGreen : AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAddPhotoSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Add Photos to Nursery Gallery',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.botanicalGreenLight,
                  child: Icon(Icons.photo_library, color: AppColors.botanicalGreen),
                ),
                title: const Text('Choose Multiple from Gallery'),
                subtitle: const Text('Select one or more photos'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMultipleImages();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.botanicalGreenLight,
                  child: Icon(Icons.camera_alt, color: AppColors.botanicalGreen),
                ),
                title: const Text('Take a Photo (Camera)'),
                subtitle: const Text('Capture plant or nursery view'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, String?>?> _showPhotoDetailsDialog() async {
    final captionCtrl = TextEditingController();
    String? selectedCategory;
    final categories = ['Greenhouse', 'Outdoor Garden', 'Display Section', 'Rare Collection', 'Work Area', 'General'];

    return showDialog<Map<String, String?>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Photo Details (Optional)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: captionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Caption / Description',
                    hintText: 'e.g. Summer orchids in bloom',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Category / Section:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: categories.map((cat) {
                    final isSel = selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      onSelected: (val) {
                        setDialogState(() {
                          selectedCategory = val ? cat : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx, {
                  'caption': captionCtrl.text.trim().isEmpty ? null : captionCtrl.text.trim(),
                  'category': selectedCategory,
                });
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showCategorySelectionDialog() async {
    String? selectedCategory;
    final categories = ['Greenhouse', 'Outdoor Garden', 'Display Section', 'Rare Collection', 'General'];

    return showDialog<String?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Select Section / Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tag these photos with a nursery section (optional):'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: categories.map((cat) {
                  final isSel = selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSel,
                    onSelected: (val) {
                      setDialogState(() {
                        selectedCategory = val ? cat : null;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selectedCategory),
              child: const Text('Continue Upload'),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullscreenViewer(GalleryImage image) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GalleryFullscreenViewer(
          image: image,
          onDeleted: () {
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final owner = context.watch<OwnerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Our Plant Gallery',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (owner.nursery != null)
              Text(
                owner.nursery!.name,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh gallery',
            onPressed: () => owner.fetchGallery(refresh: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPhotoSheet,
        backgroundColor: AppColors.botanicalGreen,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('Add Photos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () => owner.fetchGallery(refresh: true),
        child: Column(
          children: [
            // Uploading progress banner
            if (owner.isUploadingGallery)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: AppColors.botanicalGreenLight.withOpacity(0.4),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Uploading photo ${owner.galleryUploadingCount + 1} of ${owner.galleryTotalToUpload}...',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Informational header note
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.photo_library_outlined, color: Colors.green.shade800, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${owner.gallery.length} Nursery Photos',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Showcase your nursery grounds, greenhouses, and displays. Gallery photos are independent of plant listings.',
                          style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Gallery content
            Expanded(
              child: _buildGalleryContent(owner),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryContent(OwnerProvider owner) {
    if (owner.isGalleryLoading && owner.gallery.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (owner.galleryError != null && owner.gallery.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(owner.galleryError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => owner.fetchGallery(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (owner.gallery.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.botanicalGreenLight.withOpacity(0.5),
                  child: const Icon(Icons.add_photo_alternate_outlined, size: 44, color: AppColors.botanicalGreen),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Gallery Photos Yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload photos of your nursery atmosphere, seasonal displays, and greenhouses to impress visiting customers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showAddPhotoSheet,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Add Your First Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.botanicalGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: owner.gallery.length,
      itemBuilder: (context, index) {
        final image = owner.gallery[index];
        return _buildGalleryGridCard(image);
      },
    );
  }

  Widget _buildGalleryGridCard(GalleryImage image) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openFullscreenViewer(image),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            CachedNetworkImage(
              imageUrl: image.url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[100],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),

            // Top Category badge
            if (image.category != null && image.category!.isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    image.category!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Bottom Caption gradient overlay
            if (image.caption != null && image.caption!.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Text(
                    image.caption!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Fullscreen Viewer Dialog ────────────────────────────────────────────────

class _GalleryFullscreenViewer extends StatefulWidget {
  final GalleryImage image;
  final VoidCallback onDeleted;

  const _GalleryFullscreenViewer({
    required this.image,
    required this.onDeleted,
  });

  @override
  State<_GalleryFullscreenViewer> createState() => _GalleryFullscreenViewerState();
}

class _GalleryFullscreenViewerState extends State<_GalleryFullscreenViewer> {
  late GalleryImage _currentImage;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.image;
  }

  Future<void> _editCaption() async {
    final ctrl = TextEditingController(text: _currentImage.caption ?? '');
    String? selectedCategory = _currentImage.category;
    final categories = ['Greenhouse', 'Outdoor Garden', 'Display Section', 'Rare Collection', 'Work Area', 'General'];

    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Photo Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Caption',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Category:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: categories.map((cat) {
                    final isSel = selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      onSelected: (val) {
                        setDialogState(() {
                          selectedCategory = val ? cat : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx, {
                  'caption': ctrl.text,
                  'category': selectedCategory,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      final success = await context.read<OwnerProvider>().updateGalleryImage(
        imageId: _currentImage.id,
        caption: result['caption'],
        category: result['category'],
      );

      if (success && mounted) {
        setState(() {
          _currentImage = _currentImage.copyWith(
            caption: result['caption'],
            category: result['category'],
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo details updated!')),
        );
      }
    }
  }

  Future<void> _deletePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('Are you sure you want to remove this photo from your nursery gallery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<OwnerProvider>().deleteGalleryImage(_currentImage.id);
      if (success && mounted) {
        widget.onDeleted();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo removed from gallery.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit details',
            onPressed: _editCaption,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            tooltip: 'Delete photo',
            onPressed: _deletePhoto,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: _currentImage.url,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                    ),
                  ),
                ),
              ),
            ),
            if ((_currentImage.caption != null && _currentImage.caption!.isNotEmpty) ||
                (_currentImage.category != null && _currentImage.category!.isNotEmpty))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.black.withOpacity(0.8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentImage.category != null && _currentImage.category!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.botanicalGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _currentImage.category!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (_currentImage.caption != null && _currentImage.caption!.isNotEmpty)
                      Text(
                        _currentImage.caption!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
