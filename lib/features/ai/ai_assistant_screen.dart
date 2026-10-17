import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/gemini_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final GeminiService _gemini = GeminiService();
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // Chat history: {'role': 'user'/'model', 'text': '...'}
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // Plant ID state
  File? _selectedImage;
  PlantIdentificationResult? _idResult;

  // Active tab: 'chat' | 'identify'
  String _activeTab = 'chat';

  // ── Gemini chat send ─────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _chatCtrl.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await _gemini.chatWithPlantAssistant(
        text,
        _messages.sublist(0, _messages.length - 1),
      );
      setState(() {
        _messages.add({'role': 'model', 'text': reply});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'model',
          'text': 'Sorry, I encountered an error. Please try again.'
        });
        _isLoading = false;
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
      _isLoading = true;
    });

    try {
      final result = await _gemini.identifyPlant(_selectedImage!);
      setState(() {
        _idResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
        title: const Text('AI Plant Assistant'),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _TabBar(
            activeTab: _activeTab,
            onTabChanged: (t) => setState(() => _activeTab = t),
          ),
        ),
      ),
      body: _activeTab == 'chat' ? _buildChat() : _buildIdentify(),
    );
  }

  // ── Chat UI ──────────────────────────────────────────────────
  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _ChatEmpty()
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
        if (_isLoading)
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
          enabled: !_isLoading,
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
            if (_isLoading)
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
              color: active ? AppColors.primaryBlue : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? AppColors.primaryBlue : AppColors.textSecondary,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ChatEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.smart_toy_outlined,
              size: 72, color: AppColors.botanicalGreen),
          SizedBox(height: 16),
          Text(
            'GoGreen AI Assistant',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary),
          ),
          SizedBox(height: 8),
          Text(
            'Ask me anything about plant care,\nwatering schedules, or pest control!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
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
              color: AppColors.primaryBlue,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryBlueLight,
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
