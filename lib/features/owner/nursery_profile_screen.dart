import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/owner_provider.dart';
import '../nurseries/models/nursery.dart';

class NurseryProfileScreen extends StatefulWidget {
  final Nursery? initialNursery;

  const NurseryProfileScreen({super.key, this.initialNursery});

  @override
  State<NurseryProfileScreen> createState() => _NurseryProfileScreenState();
}

class _NurseryProfileScreenState extends State<NurseryProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _phoneController;

  File? _selectedImageFile;
  String? _currentLogoUrl;
  bool _isUploadingLogo = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final nursery = widget.initialNursery ?? context.read<OwnerProvider>().nursery;
    _nameController = TextEditingController(text: nursery?.name ?? '');
    _descController = TextEditingController(text: nursery?.description ?? '');
    _addressController = TextEditingController(text: nursery?.address ?? '');
    _cityController = TextEditingController(text: nursery?.city ?? '');
    _stateController = TextEditingController(text: nursery?.state ?? '');
    _phoneController = TextEditingController(text: nursery?.phone ?? '');
    _currentLogoUrl = nursery?.logoUrl ?? nursery?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _selectedImageFile = File(picked.path);
        _isUploadingLogo = true;
      });

      final owner = context.read<OwnerProvider>();
      final uploadedUrl = await owner.uploadLogo(_selectedImageFile!);

      if (mounted) {
        setState(() {
          _isUploadingLogo = false;
          if (uploadedUrl != null) {
            _currentLogoUrl = uploadedUrl;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logo uploaded to cloud successfully!'),
                backgroundColor: AppColors.botanicalGreen,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(owner.errorMessage ?? 'Failed to upload logo image.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
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
                'Nursery Logo / Storefront Photo',
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
                title: const Text('Take a Photo'),
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
              if (_currentLogoUrl != null || _selectedImageFile != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  ),
                  title: const Text('Remove Logo', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedImageFile = null;
                      _currentLogoUrl = null;
                    });
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

    setState(() => _isSaving = true);
    final owner = context.read<OwnerProvider>();
    final isNew = owner.nursery == null;
    bool success = false;

    if (isNew) {
      success = await owner.registerNursery(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        phone: _phoneController.text.trim(),
        logoUrl: _currentLogoUrl,
      );
    } else {
      success = await owner.updateNurseryProfile(
        nurseryId: owner.nursery!.id,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        phone: _phoneController.text.trim(),
        logoUrl: _currentLogoUrl,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNew ? 'Nursery registered successfully!' : 'Profile updated successfully!'),
            backgroundColor: AppColors.botanicalGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(owner.errorMessage ?? 'Failed to save nursery profile.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = context.watch<OwnerProvider>();
    final nursery = owner.nursery;
    final isNew = nursery == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isNew ? 'Register Nursery' : 'Nursery Profile'),
        actions: [
          if (!isNew && owner.myNurseries.length > 1)
            PopupMenuButton<Nursery>(
              tooltip: 'Switch Nursery',
              icon: const Icon(Icons.swap_horiz_rounded),
              onSelected: (selected) {
                owner.selectNursery(selected);
                setState(() {
                  _nameController.text = selected.name;
                  _descController.text = selected.description ?? '';
                  _addressController.text = selected.address ?? '';
                  _cityController.text = selected.city ?? '';
                  _stateController.text = selected.state ?? '';
                  _phoneController.text = selected.phone ?? '';
                  _currentLogoUrl = selected.logoUrl ?? selected.imageUrl;
                  _selectedImageFile = null;
                });
              },
              itemBuilder: (ctx) => owner.myNurseries.map((n) {
                return PopupMenuItem<Nursery>(
                  value: n,
                  child: Row(
                    children: [
                      Icon(
                        n.id == nursery.id ? Icons.check_circle : Icons.store_outlined,
                        color: n.id == nursery.id ? AppColors.botanicalGreen : AppColors.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          n.name,
                          style: TextStyle(
                            fontWeight: n.id == nursery.id ? FontWeight.w700 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // ── Storefront / Logo Avatar ───────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _isUploadingLogo
                            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                            : _selectedImageFile != null
                                ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                                : (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty)
                                    ? CachedNetworkImage(
                                        imageUrl: _currentLogoUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        errorWidget: (_, __, ___) => const Icon(
                                          Icons.storefront_rounded,
                                          color: AppColors.botanicalGreen,
                                          size: 48,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.storefront_rounded,
                                        color: AppColors.botanicalGreen,
                                        size: 48,
                                      ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingLogo ? null : _showImageSourcePicker,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.botanicalGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _isUploadingLogo ? null : _showImageSourcePicker,
                  child: Text(
                    _currentLogoUrl != null ? 'Change Store Logo' : 'Upload Store Logo',
                    style: const TextStyle(
                      color: AppColors.botanicalGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Verification Status Card ───────────────────────
              if (!isNew) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: nursery.isVerified
                        ? AppColors.botanicalGreenLight
                        : AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: nursery.isVerified
                          ? AppColors.botanicalGreen.withOpacity(0.3)
                          : AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        nursery.isVerified
                            ? Icons.verified_rounded
                            : Icons.access_time_rounded,
                        color: nursery.isVerified ? AppColors.botanicalGreen : AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nursery.isVerified
                                  ? 'Verified Nursery Partner'
                                  : (nursery.isActive ? 'Under Review by Admin' : 'Profile Inactive'),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: nursery.isVerified
                                    ? AppColors.botanicalGreenDark
                                    : AppColors.warning,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nursery.isVerified
                                  ? 'Your nursery and plants are visible to all customers.'
                                  : 'Plant listings will be published after admin approval.',
                              style: TextStyle(
                                fontSize: 12,
                                color: nursery.isVerified
                                    ? AppColors.botanicalGreenDark.withOpacity(0.85)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Section: Basic Details ─────────────────────────
              _buildSectionHeader('NURSERY INFORMATION'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nursery Name *',
                  hintText: 'e.g. Green Paradise Botanical Sanctuary',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Nursery name is required';
                  if (val.trim().length > 120) return 'Name must be under 120 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone Number',
                  hintText: 'e.g. +1 555-019-2834',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'About Your Nursery',
                  hintText: 'Describe your specialties, plant varieties, organic soil, or services...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 50),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Section: Location Details ──────────────────────
              _buildSectionHeader('LOCATION & ADDRESS'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  hintText: 'e.g. 104 Botanical Way, Suite 4',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        hintText: 'e.g. Austin',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State / Province',
                        hintText: 'e.g. TX',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // ── Save Changes Button ────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(isNew ? 'Submit Nursery for Approval' : 'Save Profile Changes'),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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
