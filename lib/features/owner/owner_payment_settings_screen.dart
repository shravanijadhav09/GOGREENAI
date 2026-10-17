import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/owner_provider.dart';

class OwnerPaymentSettingsScreen extends StatefulWidget {
  const OwnerPaymentSettingsScreen({super.key});

  @override
  State<OwnerPaymentSettingsScreen> createState() => _OwnerPaymentSettingsScreenState();
}

class _OwnerPaymentSettingsScreenState extends State<OwnerPaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _upiIdController = TextEditingController();
  final _picker = ImagePicker();

  File? _selectedQrImage;
  String? _currentQrUrl;
  String? _currentQrPublicId;

  bool _isUpiEnabled = false;
  bool _isPayAtPickupEnabled = true;
  bool _isCodEnabled = false;

  bool _isSaving = false;
  bool _isUploadingQr = false;

  @override
  void initState() {
    super.initState();
    final nursery = context.read<OwnerProvider>().nursery;
    if (nursery != null) {
      _upiIdController.text = nursery.upiId ?? '';
      _currentQrUrl = nursery.upiQrUrl;
      _currentQrPublicId = nursery.upiQrPublicId;
      _isUpiEnabled = nursery.isUpiEnabled;
      _isPayAtPickupEnabled = nursery.isPayAtPickupEnabled;
      _isCodEnabled = nursery.isCodEnabled;
    }
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _pickQrImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (picked != null) {
        setState(() {
          _selectedQrImage = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick QR code: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isUpiEnabled && _selectedQrImage == null && (_currentQrUrl == null || _currentQrUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a UPI QR code image or disable UPI payments.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (!_isUpiEnabled && !_isPayAtPickupEnabled && !_isCodEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one payment method must remain enabled for customers.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final ownerProvider = context.read<OwnerProvider>();

    try {
      String? finalQrUrl = _currentQrUrl;
      String? finalQrPublicId = _currentQrPublicId;

      if (_selectedQrImage != null) {
        setState(() => _isUploadingQr = true);
        final uploadResult = await ownerProvider.uploadPaymentQr(_selectedQrImage!);
        setState(() => _isUploadingQr = false);

        if (uploadResult != null) {
          finalQrUrl = uploadResult['url'];
          finalQrPublicId = uploadResult['publicId'];
        } else {
          throw Exception(ownerProvider.paymentSettingsError ?? 'Failed to upload QR image.');
        }
      }

      final success = await ownerProvider.updatePaymentSettings(
        upiId: _upiIdController.text.trim(),
        upiQrUrl: finalQrUrl,
        upiQrPublicId: finalQrPublicId,
        isUpiEnabled: _isUpiEnabled,
        isPayAtPickupEnabled: _isPayAtPickupEnabled,
        isCodEnabled: _isCodEnabled,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment settings saved successfully!'),
            backgroundColor: AppColors.botanicalGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ownerProvider.paymentSettingsError ?? 'Failed to save settings.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isUploadingQr = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nursery = context.watch<OwnerProvider>().nursery;

    if (nursery == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Settings')),
        body: const Center(
          child: Text('Please register and set up your nursery profile first.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nursery Payment Settings'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.botanicalGreenLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.botanicalGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.botanicalGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manual Direct Payments',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Receive customer payments directly via UPI, cash on delivery, or pickup without gateway transaction fees.',
                            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Section 1: UPI Payments ─────────────────────────
              _buildSectionHeader('UPI PAYMENT SETTINGS', Icons.qr_code_rounded),
              const SizedBox(height: 12),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Accept UPI Payments',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      subtitle: const Text(
                        'Customers scan your QR code and transfer funds via GPay, PhonePe, Paytm, or BHIM.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                      value: _isUpiEnabled,
                      activeColor: AppColors.botanicalGreen,
                      onChanged: (val) => setState(() => _isUpiEnabled = val),
                    ),

                    if (_isUpiEnabled) ...[
                      const Divider(height: 24),
                      TextFormField(
                        controller: _upiIdController,
                        decoration: InputDecoration(
                          labelText: 'Nursery UPI ID / VPA *',
                          hintText: 'e.g. greenplants@okaxis, 9876543210@paytm',
                          prefixIcon: const Icon(Icons.alternate_email, color: AppColors.botanicalGreen),
                          helperText: 'Customers can tap to copy this ID directly in their UPI app.',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (!_isUpiEnabled) return null;
                          if (val == null || val.trim().isEmpty) {
                            return 'UPI ID is required when UPI payment is enabled.';
                          }
                          if (!val.contains('@') || val.length < 5) {
                            return 'Enter a valid UPI ID (e.g. yourname@bank)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // QR Code Upload Box
                      const Text(
                        'UPI QR Code Image',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),

                      Center(
                        child: GestureDetector(
                          onTap: _pickQrImage,
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedQrImage != null || _currentQrUrl != null
                                    ? AppColors.botanicalGreen
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (_selectedQrImage != null)
                                    Image.file(
                                      _selectedQrImage!,
                                      width: 220,
                                      height: 220,
                                      fit: BoxFit.cover,
                                    )
                                  else if (_currentQrUrl != null && _currentQrUrl!.isNotEmpty)
                                    CachedNetworkImage(
                                      imageUrl: _currentQrUrl!,
                                      width: 220,
                                      height: 220,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (_, __, ___) => const Center(
                                        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                      ),
                                    )
                                  else
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.qr_code_scanner_rounded, size: 48, color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap to upload QR code',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'JPEG, PNG or WebP',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  if (_isUploadingQr)
                                    Container(
                                      color: Colors.black45,
                                      child: const Center(
                                        child: CircularProgressIndicator(color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _pickQrImage,
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: Text(
                            _selectedQrImage != null || _currentQrUrl != null
                                ? 'Replace QR Image'
                                : 'Choose QR from Gallery',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.botanicalGreen,
                            side: const BorderSide(color: AppColors.botanicalGreen),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

              const SizedBox(height: 24),

              // ── Section 2: Fulfillment & Offline Payment Options ───
              _buildSectionHeader('OFFLINE & PICKUP OPTIONS', Icons.storefront_outlined),
              const SizedBox(height: 12),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Pay at Nursery / Self-Pickup',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      subtitle: const Text(
                        'Customers reserve plants through the app and pay cash or UPI when collecting in person.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                      value: _isPayAtPickupEnabled,
                      activeColor: AppColors.botanicalGreen,
                      onChanged: (val) => setState(() => _isPayAtPickupEnabled = val),
                    ),
                    const Divider(height: 20),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Cash on Delivery (COD)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      subtitle: const Text(
                        'Enable if your nursery delivers directly and collects payment at the customer door.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                      value: _isCodEnabled,
                      activeColor: AppColors.botanicalGreen,
                      onChanged: (val) => setState(() => _isCodEnabled = val),
                    ),
                  ],
                ),
              ),
            ),

              const SizedBox(height: 24),

              // ── Section 3: Live Customer Preview ─────────────────
              _buildSectionHeader('CUSTOMER VIEW PREVIEW', Icons.visibility_outlined),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.preview_outlined, color: AppColors.primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Payment methods offered by ${nursery.name}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_isUpiEnabled)
                          Chip(
                            avatar: const Icon(Icons.qr_code, size: 16, color: Colors.blue),
                            label: Text('UPI (${_upiIdController.text.isNotEmpty ? _upiIdController.text : "ID required"})'),
                            backgroundColor: Colors.blue.shade50,
                          ),
                        if (_isPayAtPickupEnabled)
                          Chip(
                            avatar: const Icon(Icons.storefront, size: 16, color: AppColors.botanicalGreen),
                            label: const Text('Pay at Nursery'),
                            backgroundColor: AppColors.botanicalGreenLight,
                          ),
                        if (_isCodEnabled)
                          Chip(
                            avatar: const Icon(Icons.payments, size: 16, color: Color(0xFF78350F)),
                            label: const Text('Cash on Delivery'),
                            backgroundColor: Colors.amber.shade50,
                          ),
                        if (!_isUpiEnabled && !_isPayAtPickupEnabled && !_isCodEnabled)
                          const Text(
                            'No payment methods currently enabled.',
                            style: TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.botanicalGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving ? 'Saving Payment Settings...' : 'Save Payment Settings',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
