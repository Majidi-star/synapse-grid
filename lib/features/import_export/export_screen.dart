import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/providers/deck_providers.dart';
import 'package:recall_app/services/anki_export_service.dart';

class AnkiExportScreen extends ConsumerStatefulWidget {
  const AnkiExportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AnkiExportScreen> createState() => _AnkiExportScreenState();
}

class _AnkiExportScreenState extends ConsumerState<AnkiExportScreen> {
  String? _selectedDeckId;
  String? _selectedDeckName;
  bool _isLoading = false;

  Future<void> _exportAndShare() async {
    if (_selectedDeckId == null || _selectedDeckName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a deck to export first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final exporter = AnkiExportService();
      final path = await exporter.exportDeckToApkg(_selectedDeckId!, _selectedDeckName!);

      setState(() {
        _isLoading = false;
      });

      // Trigger share dialog
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Synap Deck Export: $_selectedDeckName',
        text: 'Review my deck "$_selectedDeckName" on Synap Spaced Repetition engine!',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGold = Color(0xFFE3C36C);
    const surfaceContainer = Color(0xFF21201B);
    const onSurface = Color(0xFFE7E2DA);
    const onSurfaceVariant = Color(0xFFCFC5B3);

    final decksAsync = ref.watch(decksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Export to Anki',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text(
              'SELECT A DECK TO EXPORT',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: decksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: primaryGold)),
              error: (err, __) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              data: (decks) {
                if (decks.isEmpty) {
                  return Center(
                    child: Text(
                      'No decks available to export.',
                      style: TextStyle(fontFamily: 'Manrope', color: onSurfaceVariant.withOpacity(0.5)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  itemCount: decks.length,
                  itemBuilder: (context, index) {
                    final deck = decks[index];
                    final isSelected = _selectedDeckId == deck.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? primaryGold : onSurface.withOpacity(0.05),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _selectedDeckId = deck.id;
                            _selectedDeckName = deck.name;
                          });
                        },
                        title: Text(
                          deck.name,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${deck.cardCount} cards',
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 12,
                            color: onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                        trailing: Radio<String>(
                          value: deck.id,
                          groupValue: _selectedDeckId,
                          activeColor: primaryGold,
                          onChanged: (val) {
                            setState(() {
                              _selectedDeckId = deck.id;
                              _selectedDeckName = deck.name;
                            });
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading || _selectedDeckId == null ? null : _exportAndShare,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGold,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppColors.background)
                    : const Text(
                        'EXPORT & SHARE .APKG',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
