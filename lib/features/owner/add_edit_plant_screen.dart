import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/owner_provider.dart';
import '../plants/models/plant.dart';

class AddEditPlantScreen extends StatefulWidget {
  final Plant? existingPlant;

  const AddEditPlantScreen({super.key, this.existingPlant});

  @override
  State<AddEditPlantScreen> createState() => _AddEditPlantScreenState();
}

class _AddEditPlantScreenState extends State<AddEditPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _categoryController;
  late TextEditingController _sizeController;
  late TextEditingController _tagsController;

  File? _selectedImageFile;
  String? _currentImageUrl;
  bool _isUploadingImage = false;
  bool _isSaving = false;

  String? _selectedSunlight;
  String? _selectedWatering;
  String? _selectedDifficulty;
  bool _isIndoor = true;
  bool _isOutdoor = false;
  bool _isPetSafe = false;
  bool _isActive = true;

  final List<String> _commonCategories = [
    'Indoor & Foliage',
    'Flowering',
    'Succulents & Cacti',
    'Herbs & Edibles',
    'Medicinal',
    'Ferns & Palms',
    'Outdoor Trees & Shrubs',
    'Air Plants',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existingPlant;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(text: p != null ? p.price.toStringAsFixed(2) : '');
    _stockController = TextEditingController(text: p != null ? '${p.stock}' : '10');
    _categoryController = TextEditingController(text: p?.category ?? 'Indoor & Foliage');
    _sizeController = TextEditingController(text: p?.sizeCm != null ? '${p!.sizeCm}' : '');
    _tagsController = TextEditingController(text: p?.tags.join(', ') ?? '');

    _currentImageUrl = p?.imageUrl;
    _selectedSunlight = p?.sunlight;
    _selectedWatering = p?.watering;
    _selectedDifficulty = p?.careDifficulty;
    _isIndoor = p?.isIndoor ?? true;
    _isOutdoor = p?.isOutdoor ?? false;
    _isPetSafe = p?.isPetSafe ?? false;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _sizeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _selectedImageFile = File(picked.path);
        _isUploadingImage = true;
      });

      final owner = context.read<OwnerProvider>();
      final uploadedUrl = await owner.uploadPlantImage(_selectedImageFile!);

      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          if (uploadedUrl != null) {
            _currentImageUrl = uploadedUrl;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Plant image uploaded to Cloudinary!'),
                backgroundColor: AppColors.botanicalGreen,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(owner.plantImageError ?? owner.inventoryError ?? 'Failed to upload plant image.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image selection error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Plant Photo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.botanicalGreenLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.botanicalGreen),
                ),
                title: const Text('Take a Photo with Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlueLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryBlue),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final sizeCm = int.tryParse(_sizeController.text.trim());
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    setState(() => _isSaving = true);
    final owner = context.read<OwnerProvider>();
    final isEditing = widget.existingPlant != null;
    bool success = false;

    if (isEditing) {
      success = await owner.updatePlant(
        plantId: widget.existingPlant!.id,
        name: _nameController.text.trim(),
        price: price,
        stock: stock,
        isActive: _isActive,
        description: _descController.text.trim(),
        imageUrl: _currentImageUrl,
        category: _categoryController.text.trim(),
        tags: tags,
        sunlight: _selectedSunlight,
        watering: _selectedWatering,
        careDifficulty: _selectedDifficulty,
        isIndoor: _isIndoor,
        isOutdoor: _isOutdoor,
        isPetSafe: _isPetSafe,
        sizeCm: sizeCm,
      );
    } else {
      success = await owner.createPlant(
        name: _nameController.text.trim(),
        price: price,
        stock: stock,
        description: _descController.text.trim(),
        imageUrl: _currentImageUrl,
        category: _categoryController.text.trim(),
        tags: tags,
        sunlight: _selectedSunlight,
        watering: _selectedWatering,
        careDifficulty: _selectedDifficulty,
        isIndoor: _isIndoor,
        isOutdoor: _isOutdoor,
        isPetSafe: _isPetSafe,
        sizeCm: sizeCm,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Plant updated successfully!' : 'Plant listed successfully!'),
            backgroundColor: AppColors.botanicalGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(owner.inventoryError ?? 'Failed to save plant listing.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingPlant != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Plant Listing' : 'Add New Plant'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // ── Plant Photo Upload Area ────────────────────────
              GestureDetector(
                onTap: _isUploadingImage ? null : _showImageSourcePicker,
                child: Container(
                  height: 190,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _isUploadingImage
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text(
                                  'Uploading to Cloudinary...',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : _selectedImageFile != null
                            ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                            : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: _currentImageUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => _buildPlaceholder(),
                                  )
                                : _buildPlaceholder(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Section: Core Product Info ─────────────────────
              _buildSectionTitle('PLANT DETAILS'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Plant Name *',
                  hintText: 'e.g. Fiddle Leaf Fig (Ficus Lyrata)',
                  prefixIcon: Icon(Icons.local_florist_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Plant name is required';
                  if (val.trim().length > 120) return 'Name too long (max 120)';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Category Selector
              DropdownButtonFormField<String>(
                value: _commonCategories.contains(_categoryController.text)
                    ? _categoryController.text
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                hint: Text(_categoryController.text.isNotEmpty ? _categoryController.text : 'Select Category'),
                items: _commonCategories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _categoryController.text = val);
                },
              ),
              const SizedBox(height: 14),

              // Price & Stock Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price (\$) *',
                        hintText: '24.99',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Price required';
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock Units *',
                        hintText: '10',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Stock required';
                        final num = int.tryParse(val.trim());
                        if (num == null || num < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe botanical features, leaf pattern, or container size...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 35),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Section: Care Specifications ───────────────────
              _buildSectionTitle('CARE & RECOMMENDATION SPECS'),
              const SizedBox(height: 12),

              // Sunlight Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSunlight,
                decoration: const InputDecoration(
                  labelText: 'Sunlight Requirement',
                  prefixIcon: Icon(Icons.wb_sunny_outlined),
                ),
                hint: const Text('Select sunlight level'),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Low / Full Shade')),
                  DropdownMenuItem(value: 'INDIRECT', child: Text('Bright Indirect Light')),
                  DropdownMenuItem(value: 'DIRECT', child: Text('Full Sunlight (Outdoors)')),
                ],
                onChanged: (val) => setState(() => _selectedSunlight = val),
              ),
              const SizedBox(height: 14),

              // Watering Dropdown
              DropdownButtonFormField<String>(
                value: _selectedWatering,
                decoration: const InputDecoration(
                  labelText: 'Watering Frequency',
                  prefixIcon: Icon(Icons.water_drop_outlined),
                ),
                hint: const Text('Select watering schedule'),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Low (Once a week or less)')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Medium (Every 2-4 days)')),
                  DropdownMenuItem(value: 'HIGH', child: Text('High (Daily watering)')),
                ],
                onChanged: (val) => setState(() => _selectedWatering = val),
              ),
              const SizedBox(height: 14),

              // Care Difficulty Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDifficulty,
                decoration: const InputDecoration(
                  labelText: 'Care Effort Difficulty',
                  prefixIcon: Icon(Icons.fitness_center_outlined),
                ),
                hint: const Text('Select care difficulty'),
                items: const [
                  DropdownMenuItem(value: 'EASY', child: Text('Easy / Low-Maintenance')),
                  DropdownMenuItem(value: 'MODERATE', child: Text('Moderate Care')),
                  DropdownMenuItem(value: 'EXPERT', child: Text('Expert / High Care')),
                ],
                onChanged: (val) => setState(() => _selectedDifficulty = val),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _sizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Approximate Mature Height (cm)',
                  hintText: 'e.g. 60',
                  prefixIcon: Icon(Icons.height_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Placement Toggles Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Suitable for Indoors', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Living room, bedroom, office', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      value: _isIndoor,
                      activeColor: AppColors.botanicalGreen,
                      onChanged: (val) => setState(() => _isIndoor = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Suitable for Outdoors', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Balcony, terrace, garden beds', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      value: _isOutdoor,
                      activeColor: AppColors.botanicalGreen,
                      onChanged: (val) => setState(() => _isOutdoor = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pet-Safe (Non-Toxic)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Safe around curious cats and dogs', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      value: _isPetSafe,
                      activeColor: AppColors.botanicalGreen,
                      onChanged: (val) => setState(() => _isPetSafe = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  hintText: 'air-purifying, easy-care, beginner, tropical',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
              ),
              const SizedBox(height: 14),

              // Active Listing Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: SwitchListTile(
                  title: const Text('Active Listing (Visible to Customers)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _isActive ? 'Published on store' : 'Draft / Hidden from public',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  value: _isActive,
                  activeColor: AppColors.botanicalGreen,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit Button ──────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(isEditing ? 'Save Changes' : 'Publish Plant Listing'),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.botanicalGreenLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_a_photo_rounded, color: AppColors.botanicalGreen, size: 28),
          ),
          const SizedBox(height: 10),
          const Text(
            'Upload Plant Product Image',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap to choose from Camera or Gallery',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppColors.textMuted,
      ),
    );
  }
}
