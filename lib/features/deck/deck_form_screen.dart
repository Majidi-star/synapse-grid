import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/models/deck.dart';
import 'package:recall_app/providers/deck_providers.dart';

import 'package:uuid/uuid.dart';

class DeckFormScreen extends ConsumerStatefulWidget {
  final Deck? deck;

  const DeckFormScreen({super.key, this.deck});

  @override
  ConsumerState<DeckFormScreen> createState() => _DeckFormScreenState();
}

class _DeckFormScreenState extends ConsumerState<DeckFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deck?.name ?? '');
    _descController = TextEditingController(text: widget.deck?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveDeck() async {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text;
      final desc = _descController.text;
      
      final service = ref.read(deckServiceProvider);
      if (widget.deck == null) {
        final newDeck = Deck(
          id: const Uuid().v4(),
          name: name,
          description: desc,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await service.createDeck(newDeck);
      } else {
        final updatedDeck = widget.deck!.copyWith(
          name: name,
          description: desc,
          updatedAt: DateTime.now(),
        );
        await service.updateDeck(updatedDeck);
      }
      
      // ignore: unused_result
      ref.refresh(decksProvider);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.deck != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Deck' : 'New Deck',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.onSurface),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(color: AppColors.outline),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  border: const UnderlineInputBorder(),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: AppColors.onSurface),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: const TextStyle(color: AppColors.outline),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  border: const UnderlineInputBorder(),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveDeck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'UPDATE DECK' : 'CREATE DECK',
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
