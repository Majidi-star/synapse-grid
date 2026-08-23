import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/providers/deck_providers.dart';
import 'package:recall_app/providers/ai_providers.dart';
import 'package:recall_app/services/mcp/local_folder_service.dart';
import 'package:recall_app/services/mcp/local_git_service.dart';
import 'package:recall_app/services/mcp/mcp_ingestion_pipeline.dart';

class McpConnectionsScreen extends ConsumerStatefulWidget {
  const McpConnectionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<McpConnectionsScreen> createState() => _McpConnectionsScreenState();
}

class _McpConnectionsScreenState extends ConsumerState<McpConnectionsScreen> {
  List<Map<String, dynamic>> _sources = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('mcp_sources');
    if (jsonStr != null) {
      try {
        final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
        setState(() {
          _sources = list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          _loading = false;
        });
        return;
      } catch (_) {}
    }
    setState(() {
      _sources = [];
      _loading = false;
    });
  }

  Future<void> _saveSources() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mcp_sources', jsonEncode(_sources));
  }

  Future<void> _addSource(String type) async {
    final decksAsync = ref.read(decksProvider);
    final decks = decksAsync.value ?? [];
    if (decks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create at least one deck before adding a sync source.')),
      );
      return;
    }

    String? selectedPath;
    if (type == 'folder') {
      selectedPath = await FilePicker.platform.getDirectoryPath();
    } else {
      // Browse repository root path
      selectedPath = await FilePicker.platform.getDirectoryPath();
    }

    if (selectedPath == null) return;

    if (mounted) {
      String? selectedDeckId = decks.first.id;
      String? selectedDeckName = decks.first.name;

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: AppColors.surfaceContainerHigh,
                title: Text(type == 'folder' ? 'Add Folder Source' : 'Add Git Repo Source', style: const TextStyle(color: AppColors.onSurface)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Path: $selectedPath', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 16),
                    const Text('Select Target Deck:', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: selectedDeckId,
                      dropdownColor: AppColors.surfaceContainerHighest,
                      items: decks.map((deck) {
                        return DropdownMenuItem<String>(
                          value: deck.id,
                          child: Text(deck.name, style: const TextStyle(color: AppColors.onSurface)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final matched = decks.firstWhere((d) => d.id == val);
                          setDialogState(() {
                            selectedDeckId = val;
                            selectedDeckName = matched.name;
                          });
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CANCEL', style: TextStyle(color: AppColors.error)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _sources.add({
                          'id': DateTime.now().millisecondsSinceEpoch.toString(),
                          'type': type,
                          'path': selectedPath,
                          'deckId': selectedDeckId,
                          'deckName': selectedDeckName,
                          'lastSync': 'Never synced',
                        });
                      });
                      _saveSources();
                      Navigator.of(context).pop();
                    },
                    child: const Text('ADD SOURCE', style: TextStyle(color: AppColors.primaryContainer)),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  Future<void> _syncSource(Map<String, dynamic> source) async {
    final generator = ref.read(aiCardGeneratorProvider);
    final pipeline = McpIngestionPipeline(generator: generator);
    
    final type = source['type'] as String;
    final path = source['path'] as String;
    final deckId = source['deckId'] as String;

    final sourceService = type == 'folder' 
        ? LocalFolderService(path) 
        : LocalGitService(path);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Syncing ${sourceService.sourceName}...')),
    );

    try {
      final newCardsCount = await pipeline.ingestFromSource(sourceService, deckId);
      
      setState(() {
        source['lastSync'] = DateTime.now().toLocal().toString().split('.').first;
      });
      _saveSources();

      if (mounted) {
        // Invalidate pending queue provider to refresh counts
        ref.invalidate(aiPendingQueueProvider(deckId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync complete! Generated $newCardsCount cards in the review queue.'),
            backgroundColor: AppColors.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeSource(String id) {
    setState(() {
      _sources.removeWhere((src) => src['id'] == id);
    });
    _saveSources();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.onSurface),
        title: const Text('Local MCP Ingestion', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monitor local files and repositories to automatically extract concepts and generate flashcards directly into your decks.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _addSource('folder'),
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('ADD FOLDER'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryContainer,
                            side: const BorderSide(color: AppColors.primaryContainer),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _addSource('git'),
                          icon: const Icon(Icons.code_rounded),
                          label: const Text('ADD GIT REPO'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryContainer,
                            side: const BorderSide(color: AppColors.primaryContainer),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text('MONITORED SOURCES', style: textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.primaryContainer)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _sources.isEmpty
                        ? Center(
                            child: Text(
                              'No directories monitored yet.',
                              style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.4)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _sources.length,
                            itemBuilder: (context, index) {
                              final src = _sources[index];
                              final isFolder = src['type'] == 'folder';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.05)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isFolder ? Icons.folder_rounded : Icons.code_rounded,
                                        color: AppColors.primaryContainer,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              src['path'].split('/').last.split('\\').last,
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Target Deck: ${src['deckName']}',
                                              style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6), fontSize: 12),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Last Sync: ${src['lastSync']}',
                                              style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.4), fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.sync_rounded, color: AppColors.primaryContainer),
                                        onPressed: () => _syncSource(src),
                                        tooltip: 'Sync Now',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_rounded, color: AppColors.error),
                                        onPressed: () => _removeSource(src['id']),
                                        tooltip: 'Remove Ingestion Source',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
