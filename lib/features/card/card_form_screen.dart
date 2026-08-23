import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/models/card.dart';
import 'package:recall_app/providers/card_providers.dart';

import 'package:uuid/uuid.dart';
import 'package:recall_app/providers/deck_providers.dart';

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

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.card?.frontText ?? '');
    _backController = TextEditingController(text: widget.card?.backText ?? '');
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  void _saveCard() async {
    if (_formKey.currentState?.validate() ?? false) {
      final front = _frontController.text;
      final back = _backController.text;
      
      final cardService = ref.read(cardServiceProvider);
      final deckService = ref.read(deckServiceProvider);
      final actualDeckId = widget.card?.deckId ?? widget.deckId!;
      
      if (widget.card == null) {
        final newCard = FlashCard(
          id: const Uuid().v4(),
          deckId: actualDeckId,
          frontText: front,
          backText: back,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await cardService.createCard(newCard);
      } else {
        final updatedCard = widget.card!.copyWith(
          frontText: front,
          backText: back,
          updatedAt: DateTime.now(),
        );
        await cardService.updateCard(updatedCard);
      }
      
      await deckService.updateCardCount(actualDeckId);
      
      // ignore: unused_result
      ref.refresh(cardsForDeckProvider(actualDeckId));
      // ignore: unused_result
      ref.refresh(decksProvider);
      
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.card != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Card' : 'New Card',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _frontController,
                style: const TextStyle(color: AppColors.onSurface),
                maxLines: null,
                minLines: 5,
                decoration: InputDecoration(
                  hintText: 'Front',
                  hintStyle: const TextStyle(color: AppColors.outline),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _backController,
                style: const TextStyle(color: AppColors.onSurface),
                maxLines: null,
                minLines: 5,
                decoration: InputDecoration(
                  hintText: 'Back',
                  hintStyle: const TextStyle(color: AppColors.outline),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Cannot be empty' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
