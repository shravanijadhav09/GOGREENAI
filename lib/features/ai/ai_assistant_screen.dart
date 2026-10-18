import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/services/gemini_service.dart';
import '../plants/models/plant.dart';
import '../plants/plant_detail_screen.dart';

class AiAssistantScreen extends StatefulWidget {
  final String initialTab;

  const AiAssistantScreen({super.key, this.initialTab = 'recommend'});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final GeminiService _gemini = GeminiService();
  final ApiClient _api = ApiClient();
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // Active tab: 'recommend' | 'chat' | 'identify'
  late String _activeTab;

  // ── Chat state ──
  final List<Map<String, String>> _messages = [];
  bool _isLoadingChat = false;

  // ── Plant ID state ──
  File? _selectedImage;
  PlantIdentificationResult? _idResult;
  bool _isLoadingId = false;

  // ── Find My Plant state ──
  String _placement = 'indoor'; // 'indoor', 'outdoor', 'both'
  String _sunlight = 'INDIRECT'; // 'LOW', 'INDIRECT', 'DIRECT'
  String _watering = 'MEDIUM'; // 'LOW', 'MEDIUM', 'HIGH'
  String _careDifficulty = 'EASY'; // 'EASY', 'MODERATE', 'EXPERT'
  String? _selectedCategory;
  bool _petSafe = false;

  bool _isFindingRecommendations = false;
  List<Map<String, dynamic>> _recommendations = [];
  String? _recommendationsError;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  // ── Recommendation Finder ────────────────────────────────────
  Future<void> _fetchRecommendations() async {
    setState(() {
      _isFindingRecommendations = true;
      _recommendationsError = null;
      _hasSearched = true;
    });

    try {
      final payload = <String, dynamic>{
        'placement': _placement,
        'sunlight': _sunlight,
        'watering': _watering,
        'careDifficulty': _careDifficulty,
        'petSafe': _petSafe,
        'topN': 8,
      };
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty && _selectedCategory != 'All') {
        payload['category'] = _selectedCategory;
      }

      final res = await _api.post(ApiConstants.recommendationsEndpoint, payload);
      final list = (res['data'] as List<dynamic>? ?? []);

      final parsed = <Map<String, dynamic>>[];
      for (final item in list) {
        if (item is Map<String, dynamic> && item['plant'] != null) {
          final plant = Plant.fromJson(item['plant'] as Map<String, dynamic>);
          final score = (item['score'] as num?)?.toDouble() ?? 0.0;
          final reasons = (item['reasons'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
          parsed.add({
            'plant': plant,
            'score': score,
            'matchPercentage': (score * 100).round(),
            'reasons': reasons,
          });
        }
      }

      if (mounted) {
        setState(() {
          _recommendations = parsed;
          _isFindingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recommendationsError = 'Could not fetch plant recommendations: $e';
          _isFindingRecommendations = false;
        });
      }
    }
  }

  // ── Gemini chat send ─────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty || _isLoadingChat) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _chatCtrl.clear();
      _isLoadingChat = true;
    });
    _scrollToBottom();

    try {
      final reply = await _gemini.chatWithPlantAssistant(
        text,
        _messages.sublist(0, _messages.length - 1),
      );
      setState(() {
        _messages.add({'role': 'model', 'text': reply});
        _isLoadingChat = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'model',
          'text': 'Sorry, I encountered an error. Please try again.'
        });
        _isLoadingChat = false;
      });
    }
    _scrollToBottom();
  }

  // ── Plant identification from camera/gallery ─────────────────
  Future<void> _pickAndIdentify(ImageSource source) async {
    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (xFile == null) return;

    setState(() {
      _selectedImage = File(xFile.path);
      _idResult = null;
      _isLoadingId = true;
    });

    try {
      final result = await _gemini.identifyPlant(_selectedImage!);
      setState(() {
        _idResult = result;
        _isLoadingId = false;
      });
    } catch (e) {
      setState(() => _isLoadingId = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Plant identification failed. Check your API key.')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'GoGreen AI Assistant',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _TabBar(
            activeTab: _activeTab,
            onTabChanged: (t) => setState(() => _activeTab = t),
          ),
        ),
      ),
      body: _buildCurrentTab(),
    );
  }

  Widget _buildCurrentTab() {
    switch (_activeTab) {
      case 'recommend':
        return _buildFindMyPlant();
      case 'identify':
        return _buildIdentify();
      case 'chat':
      default:
        return _buildChat();
    }
  }

  // ── Find My Plant UI ─────────────────────────────────────────
  Widget _buildFindMyPlant() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner explanation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E824C), Color(0xFF27AE60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.psychology_alt_outlined, color: Colors.white, size: 36),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find My Plant — Smart Match',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Set your home preferences and our AI engine will match the best available plants from verified nurseries.',
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Preferences Form Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Placement
                const Text(
                  '1. Placement Space',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChoiceChip('Indoor', _placement == 'indoor', () {
                      setState(() => _placement = 'indoor');
                    }),
                    _buildChoiceChip('Outdoor', _placement == 'outdoor', () {
                      setState(() => _placement = 'outdoor');
                    }),
                    _buildChoiceChip('Both / Flexible', _placement == 'both', () {
                      setState(() => _placement = 'both');
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Sunlight
                const Text(
                  '2. Sunlight Availability',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChoiceChip('Low Light', _sunlight == 'LOW', () {
                      setState(() => _sunlight = 'LOW');
                    }),
                    _buildChoiceChip('Indirect Bright', _sunlight == 'INDIRECT', () {
                      setState(() => _sunlight = 'INDIRECT');
                    }),
                    _buildChoiceChip('Direct Sunlight', _sunlight == 'DIRECT', () {
                      setState(() => _sunlight = 'DIRECT');
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Watering
                const Text(
                  '3. Watering Routine',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChoiceChip('Low (Sparse)', _watering == 'LOW', () {
                      setState(() => _watering = 'LOW');
                    }),
                    _buildChoiceChip('Medium (Moderate)', _watering == 'MEDIUM', () {
                      setState(() => _watering = 'MEDIUM');
                    }),
                    _buildChoiceChip('High (Frequent)', _watering == 'HIGH', () {
                      setState(() => _watering = 'HIGH');
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Care Difficulty
                const Text(
                  '4. Care Effort & Experience',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChoiceChip('Beginner / Easy', _careDifficulty == 'EASY', () {
                      setState(() => _careDifficulty = 'EASY');
                    }),
                    _buildChoiceChip('Moderate', _careDifficulty == 'MODERATE', () {
                      setState(() => _careDifficulty = 'MODERATE');
                    }),
                    _buildChoiceChip('Expert / Green Thumb', _careDifficulty == 'EXPERT', () {
                      setState(() => _careDifficulty = 'EXPERT');
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Category (Optional)
                const Text(
                  '5. Plant Category (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildChoiceChip('Any Category', _selectedCategory == null, () {
                      setState(() => _selectedCategory = null);
                    }),
                    _buildChoiceChip('Indoor Plants', _selectedCategory == 'Indoor Plants', () {
                      setState(() => _selectedCategory = 'Indoor Plants');
                    }),
                    _buildChoiceChip('Outdoor Plants', _selectedCategory == 'Outdoor Plants', () {
                      setState(() => _selectedCategory = 'Outdoor Plants');
                    }),
                    _buildChoiceChip('Medicinal / Aushadhi', _selectedCategory == 'Medicinal', () {
                      setState(() => _selectedCategory = 'Medicinal');
                    }),
                    _buildChoiceChip('Flowering', _selectedCategory == 'Flowering', () {
                      setState(() => _selectedCategory = 'Flowering');
                    }),
                    _buildChoiceChip('Succulent', _selectedCategory == 'Succulent', () {
                      setState(() => _selectedCategory = 'Succulent');
                    }),
                  ],
                ),
                const SizedBox(height: 12),

                // 6. Pet Safe Switch
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.botanicalGreen,
                  title: const Text(
                    '🐾 Only Pet-Safe Plants',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Filter out plants that might be toxic to dogs & cats',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  value: _petSafe,
                  onChanged: (val) => setState(() => _petSafe = val),
                ),
                const SizedBox(height: 16),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isFindingRecommendations ? null : _fetchRecommendations,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.botanicalGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isFindingRecommendations
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _isFindingRecommendations ? 'Analyzing Catalogue…' : 'Find Matching Plants',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recommendations Results
          if (_recommendationsError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _recommendationsError!,
                style: TextStyle(color: Colors.red.shade800, fontSize: 13),
              ),
            ),

          if (_hasSearched && !_isFindingRecommendations && _recommendations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.nature_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No matching nursery plants found for these exact filters.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Try widening your placement, watering, or pet safety filters.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          if (_recommendations.isNotEmpty) ...[
            Text(
              'Matched Plants (${_recommendations.length})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recommendations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (ctx, index) {
                final item = _recommendations[index];
                final Plant plant = item['plant'] as Plant;
                final int matchPct = item['matchPercentage'] as int;
                final List<String> reasons = item['reasons'] as List<String>;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => PlantDetailScreen(plant: plant),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Plant Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  color: AppColors.botanicalGreenLight,
                                  child: plant.imageUrl != null && plant.imageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: plant.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => const Icon(
                                            Icons.eco,
                                            color: AppColors.botanicalGreen,
                                            size: 36,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.eco,
                                          color: AppColors.botanicalGreen,
                                          size: 36,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            plant.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: matchPct >= 80
                                                ? AppColors.botanicalGreenLight
                                                : Colors.amber.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$matchPct% Match',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: matchPct >= 80
                                                  ? AppColors.botanicalGreenDark
                                                  : Colors.amber.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${plant.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: AppColors.botanicalGreenDark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (plant.nurseryName != null &&
                                        plant.nurseryName!.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.storefront,
                                              size: 13, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Available at ${plant.nurseryName}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (reasons.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: reasons
                                  .map((r) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('✓ ',
                                                style: TextStyle(
                                                    color: AppColors.botanicalGreen,
                                                    fontWeight: FontWeight.bold)),
                                            Expanded(
                                              child: Text(
                                                r,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textPrimary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.botanicalGreenLight,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.botanicalGreenDark : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  // ── Chat UI ──────────────────────────────────────────────────
  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const _ChatEmpty()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    return _ChatBubble(
                      text: msg['text']!,
                      isUser: msg['role'] == 'user',
                    );
                  },
                ),
        ),
        if (_isLoadingChat)
          const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.botanicalGreen,
              ),
            ),
          ),
        _ChatInput(
          controller: _chatCtrl,
          onSend: _sendMessage,
          enabled: !_isLoadingChat,
        ),
      ],
    );
  }

  // ── Plant Identifier UI ──────────────────────────────────────
  Widget _buildIdentify() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_selectedImage == null) _PickerButtons(onPick: _pickAndIdentify),
          if (_selectedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_selectedImage!,
                  height: 220, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            if (_isLoadingId)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(color: AppColors.botanicalGreen),
              ),
            if (_idResult != null) _IdentificationResult(result: _idResult!),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _selectedImage = null;
                _idResult = null;
              }),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Another Plant'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Subwidgets ────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  const _TabBar({required this.activeTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Tab(label: 'Find My Plant', id: 'recommend', activeTab: activeTab, onTap: onTabChanged)),
        Expanded(child: _Tab(label: 'Chat', id: 'chat', activeTab: activeTab, onTap: onTabChanged)),
        Expanded(child: _Tab(label: 'Identify Plant', id: 'identify', activeTab: activeTab, onTap: onTabChanged)),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label, id, activeTab;
  final ValueChanged<String> onTap;

  const _Tab({
    required this.label,
    required this.id,
    required this.activeTab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = id == activeTab;
    return GestureDetector(
      onTap: () => onTap(id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.botanicalGreen : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.botanicalGreen : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.botanicalGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _ChatEmpty extends StatelessWidget {
  const _ChatEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.spa_outlined, size: 54, color: Colors.green.shade300),
            const SizedBox(height: 12),
            const Text(
              'Ask anything about your plants!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'e.g. "Why are my Monstera leaves turning yellow?" or "How often should I water my Snake Plant?"',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  const _ChatInput({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Ask about any plant…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send_rounded),
              color: AppColors.botanicalGreen,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.botanicalGreenLight,
                shape: const CircleBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerButtons extends StatelessWidget {
  final Function(ImageSource) onPick;
  const _PickerButtons({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.botanicalGreenLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.botanicalGreen, width: 1.5),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco, size: 64, color: AppColors.botanicalGreen),
                SizedBox(height: 8),
                Text('Take or upload a photo to identify a plant',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => onPick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onPick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IdentificationResult extends StatelessWidget {
  final PlantIdentificationResult result;
  const _IdentificationResult({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.commonName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _ConfidenceBadge(confidence: result.confidence),
            ],
          ),
          if (result.scientificName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              result.scientificName,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(result.briefDescription,
              style: const TextStyle(
                  color: AppColors.textSecondary, height: 1.4, fontSize: 14)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.water_drop_outlined, label: result.watering),
              _InfoChip(icon: Icons.wb_sunny_outlined, label: result.sunlight),
              _InfoChip(icon: Icons.fitness_center, label: result.careDifficulty),
              if (result.isPetSafe)
                const _InfoChip(
                    icon: Icons.pets, label: 'Pet Safe', positive: true),
              if (result.isIndoor)
                const _InfoChip(icon: Icons.home_outlined, label: 'Indoor'),
              if (result.isOutdoor)
                const _InfoChip(icon: Icons.park_outlined, label: 'Outdoor'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final String confidence;
  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (confidence) {
      case 'high':
        color = AppColors.botanicalGreen;
        break;
      case 'medium':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        confidence.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool positive;

  const _InfoChip(
      {required this.icon, required this.label, this.positive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: positive ? AppColors.botanicalGreenLight : AppColors.borderLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: positive
                  ? AppColors.botanicalGreen
                  : AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: positive ? AppColors.botanicalGreen : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
