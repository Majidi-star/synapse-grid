import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/models/card.dart';
import 'package:recall_app/providers/card_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:recall_app/providers/deck_providers.dart';
import 'cloze_editor.dart';
import 'image_occlusion_editor.dart';
import 'widgets/voice_recorder_widget.dart';
import 'package:recall_app/services/media_service.dart';
import 'package:recall_app/services/card_service.dart';
import 'package:recall_app/models/media_attachment.dart';

class CardFormScreen extends ConsumerStatefulWidget {
  final String? deckId;
  final FlashCard? card;

  const CardFormScreen({
    super.key,
    this.deckId,
    this.card,
  }) : assert(deckId != null || card != null, 'Must provide deckId or card');

  @override
  ConsumerState<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends ConsumerState<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _frontController;
  late TextEditingController _backController;

  CardType _selectedType = CardType.basic;

  // Cloze data
  String _clozeText = '';

  // Image Occlusion data
  String? _occlusionImageFilePath;
  List<OcclusionRegion> _occlusionRegions = [];

  // Recorded Audio Path
  String? _recordedAudioPath;

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    _frontController = TextEditingController(text: card?.frontText ?? '');
    _backController = TextEditingController(text: card?.backText ?? '');
    
    if (card != null) {
      _selectedType = card.cardType;
      if (_selectedType == CardType.cloze && card.extraData != null) {
        try {
          final data = jsonDecode(card.extraData!);
          _clozeText = data['clozeText'] as String? ?? '';
        } catch (_) {}
      } else if (_selectedType == CardType.imageOcclusion && card.extraData != null) {
        try {
          final data = jsonDecode(card.extraData!);
          _occlusionImageFilePath = data['imagePath'] as String?;
          final regs = data['regions'] as List? ?? [];
          _occlusionRegions = regs.map((r) => OcclusionRegion.fromJson(r as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  void _saveCard() async {
    final cardService = ref.read(cardServiceProvider);
    final deckService = ref.read(deckServiceProvider);
    final mediaService = MediaService();
    final actualDeckId = widget.card?.deckId ?? widget.deckId!;

    String front = '';
    String back = '';
    String? extraData;

    if (_selectedType == CardType.basic || _selectedType == CardType.bidirectional) {
      if (!_formKey.currentState!.validate()) return;
      front = _frontController.text;
      back = _backController.text;
    } else if (_selectedType == CardType.cloze) {
      if (_clozeText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cloze text cannot be empty')),
        );
        return;
      }
      if (ClozeParser.getClozeIndices(_clozeText).isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one cloze deletion block (e.g. {{c1::word}})')),
        );
        return;
      }
      front = _clozeText;
    } else if (_selectedType == CardType.imageOcclusion) {
      if (_occlusionImageFilePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload an image first')),
        );
        return;
      }
      if (_occlusionRegions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please mask at least one region on the image')),
        );
        return;
      }
      front = _occlusionImageFilePath!;
      extraData = jsonEncode({
        'imagePath': _occlusionImageFilePath,
        'regions': _occlusionRegions.map((r) => r.toJson()).toList(),
      });
    }

    final cardId = widget.card?.id ?? const Uuid().v4();

    // Copy audio if recorded
    if (_recordedAudioPath != null) {
      final audioFile = File(_recordedAudioPath!);
      if (await audioFile.exists()) {
        final attachment = await mediaService.saveMedia(cardId, audioFile, MediaType.audio);
        extraData = jsonEncode({
          if (extraData != null) ...jsonDecode(extraData),
          'audioPath': attachment.localPath,
        });
      }
    }

    if (widget.card == null) {
      final newCard = FlashCard(
        id: cardId,
        deckId: actualDeckId,
        frontText: front,
        backText: back,
        cardType: _selectedType,
        extraData: extraData,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await cardService.createCard(newCard);
    } else {
      final updatedCard = widget.card!.copyWith(
        frontText: front,
        backText: back,
        cardType: _selectedType,
        extraData: extraData,
        updatedAt: DateTime.now(),
      );
      await cardService.updateCard(updatedCard);
    }

    await deckService.updateCardCount(actualDeckId);

    // Refresh providers
    // ignore: unused_result
    ref.refresh(cardsForDeckProvider(actualDeckId));
    // ignore: unused_result
    ref.refresh(decksProvider);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.card != null;
    const primaryGold = Color(0xFFE3C36C);
    const onSurface = Color(0xFFE7E2DA);
    const surfaceContainer = Color(0xFF21201B);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Card' : 'New Card',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Card Type Selector Segmented Row
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: CardType.values.map((type) {
                    final isSelected = _selectedType == type;
                    String label = 'Basic';
                    if (type == CardType.cloze) label = 'Cloze';
                    if (type == CardType.bidirectional) label = '2-Way';
                    if (type == CardType.imageOcclusion) label = 'Occlude';

                    return Expanded(
                      child: GestureDetector(
                        onTap: isEdit
                            ? null // Prevent changing card type in edit mode to preserve consistency
                            : () {
                                setState(() {
                                  _selectedType = type;
                                });
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryGold : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.background
                                    : onSurface.withOpacity(isEdit ? 0.3 : 0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic content fields
              if (_selectedType == CardType.basic || _selectedType == CardType.bidirectional) ...[
                TextFormField(
                  controller: _frontController,
                  style: const TextStyle(color: AppColors.onSurface, fontFamily: 'Manrope'),
                  maxLines: null,
                  minLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Front side prompt',
                    hintStyle: TextStyle(color: AppColors.outline.withOpacity(0.5)),
                    filled: true,
                    fillColor: AppColors.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: primaryGold, width: 1.5),
                    ),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Front cannot be empty' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _backController,
                  style: const TextStyle(color: AppColors.onSurface, fontFamily: 'Manrope'),
                  maxLines: null,
                  minLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Back side answer',
                    hintStyle: TextStyle(color: AppColors.outline.withOpacity(0.5)),
                    filled: true,
                    fillColor: AppColors.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: primaryGold, width: 1.5),
                    ),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Back cannot be empty' : null,
                ),
                const SizedBox(height: 16),
                VoiceRecorderWidget(
                  onRecordingComplete: (filePath) {
                    setState(() {
                      _recordedAudioPath = filePath;
                    });
                  },
                ),
              ] else if (_selectedType == CardType.cloze) ...[
                ClozeEditor(
                  initialText: _clozeText,
                  onChanged: (text) {
                    _clozeText = text;
                  },
                ),
              ] else if (_selectedType == CardType.imageOcclusion) ...[
                ImageOcclusionEditor(
                  initialImageFilePath: _occlusionImageFilePath,
                  initialRegions: _occlusionRegions,
                  onChanged: (filePath, regions) {
                    _occlusionImageFilePath = filePath;
                    _occlusionRegions = regions;
                  },
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGold,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'UPDATE CARD' : 'SAVE CARD',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.background,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Geist',
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
