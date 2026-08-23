import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/services/anki_import_service.dart';
import 'package:recall_app/providers/deck_providers.dart';

class AnkiImportScreen extends ConsumerStatefulWidget {
  const AnkiImportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AnkiImportScreen> createState() => _AnkiImportScreenState();
}

class _AnkiImportScreenState extends ConsumerState<AnkiImportScreen> {
  bool _isLoading = false;
  AnkiImportResult? _result;
  String? _error;

  Future<void> _pickAndImport() async {
    final fileResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apkg'],
    );

    if (fileResult == null || fileResult.files.single.path == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    try {
      final importer = AnkiImportService();
      final res = await importer.importApkg(fileResult.files.single.path!);
      
      setState(() {
        _result = res;
        _isLoading = false;
      });

      // Refresh deck list
      ref.refresh(decksProvider);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGold = Color(0xFFE3C36C);
    const surfaceContainer = Color(0xFF21201B);
    const onSurface = Color(0xFFE7E2DA);
    const onSurfaceVariant = Color(0xFFCFC5B3);

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
          'Import Anki Deck',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: onSurface.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.download_rounded, size: 64, color: primaryGold),
                  const SizedBox(height: 16),
                  const Text(
                    'Import from Anki (.apkg)',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select an .apkg file containing Anki flashcard collections and media resources.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      color: onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _pickAndImport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: AppColors.background)
                          : const Text(
                              'SELECT .APKG FILE',
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                        SizedBox(width: 8),
                        Text(
                          'Import Successful!',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('- Decks imported: ${_result!.decksImported}', style: const TextStyle(color: onSurface, fontFamily: 'Manrope')),
                    Text('- Cards/Notes compiled: ${_result!.cardsImported}', style: const TextStyle(color: onSurface, fontFamily: 'Manrope')),
                    Text('- Media attachments: ${_result!.mediaImported}', style: const TextStyle(color: onSurface, fontFamily: 'Manrope')),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Import Failed:\n$_error',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
