import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/providers/ai_providers.dart';
import '../../core/router/app_router.dart';
import 'review_queue_screen.dart';

class AiGenerateScreen extends ConsumerStatefulWidget {
  final String deckId;
  final String deckName;

  const AiGenerateScreen({
    Key? key,
    required this.deckId,
    required this.deckName,
  }) : super(key: key);

  @override
  ConsumerState<AiGenerateScreen> createState() => _AiGenerateScreenState();
}

class _AiGenerateScreenState extends ConsumerState<AiGenerateScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  String? _pdfFilePath;
  String? _pdfFileName;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pdfFilePath = result.files.single.path;
        _pdfFileName = result.files.single.name;
        _textController.clear(); // Clear text field if PDF is loaded
      });
    }
  }

  void _clearPdf() {
    setState(() {
      _pdfFilePath = null;
      _pdfFileName = null;
    });
  }

  Future<void> _generateCards() async {
    final generator = ref.read(aiCardGeneratorProvider);
    final pdfService = ref.read(pdfServiceProvider);

    String textToProcess = '';
    if (_pdfFilePath != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        textToProcess = await pdfService.extractText(_pdfFilePath!);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read PDF: $e')),
        );
        return;
      }
    } else {
      textToProcess = _textController.text.trim();
    }

    if (textToProcess.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text or select a PDF first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await generator.generateFromText(textToProcess, widget.deckId);
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewQueueScreen(
              deckId: widget.deckId,
              deckName: widget.deckName,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generation failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGold = Color(0xFFE3C36C);
    const surfaceContainer = Color(0xFF21201B);
    const onSurface = Color(0xFFE7E2DA);
    const onSurfaceVariant = Color(0xFFCFC5B3);

    final activeProviderAsync = ref.watch(activeAiProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI Card Generator',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Active Provider Status
                activeProviderAsync.when(
                  data: (provider) {
                    if (provider == null) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'No Active AI Provider',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please configure an active AI provider in settings to generate cards.',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => AppRouter.goToSettings(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Configure Settings'),
                            ),
                          ],
                        ),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: onSurface.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.psychology_rounded, color: primaryGold),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Provider: ${provider.name}',
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: onSurface,
                                  ),
                                ),
                                Text(
                                  'Model: ${provider.selectedModel ?? "Default"}',
                                  style: TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 11,
                                    color: onSurfaceVariant.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 50),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const Text(
                  'SOURCE TEXT OR PDF',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                // Pasted Text box
                if (_pdfFilePath == null)
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    style: const TextStyle(fontFamily: 'Manrope', color: onSurface),
                    decoration: InputDecoration(
                      hintText: 'Paste study text, lecture notes, or articles here...',
                      hintStyle: TextStyle(color: onSurfaceVariant.withOpacity(0.4)),
                      filled: true,
                      fillColor: surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: primaryGold, width: 1.5),
                      ),
                    ),
                  ),

                if (_pdfFilePath != null)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryGold.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, size: 48, color: primaryGold),
                        const SizedBox(height: 12),
                        Text(
                          _pdfFileName ?? 'Selected PDF Document',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _clearPdf,
                          child: const Text(
                            'Remove PDF',
                            style: TextStyle(color: Colors.redAccent, fontFamily: 'Geist'),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Select PDF alternate trigger
                if (_pdfFilePath == null)
                  OutlinedButton.icon(
                    onPressed: _pickPdf,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: onSurface,
                      side: BorderSide(color: onSurface.withOpacity(0.1)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.upload_file_rounded, size: 20),
                    label: const Text(
                      'Select study PDF instead',
                      style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.w600),
                    ),
                  ),

                const SizedBox(height: 32),

                // Generate button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _generateCards,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGold,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'GENERATE CARDS',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: primaryGold),
                    SizedBox(height: 24),
                    Text(
                      'Synthesizing flashcards...',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Analyzing main concepts and extracting facts.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        color: onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
