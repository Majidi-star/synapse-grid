import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/core/router/app_router.dart';
import 'package:recall_app/services/collaboration_service.dart';
import 'package:recall_app/services/webdav_sync_service.dart';

class DeckShareScreen extends StatefulWidget {
  final String deckId;
  final String deckName;

  const DeckShareScreen({
    Key? key,
    required this.deckId,
    required this.deckName,
  }) : super(key: key);

  @override
  State<DeckShareScreen> createState() => _DeckShareScreenState();
}

class _DeckShareScreenState extends State<DeckShareScreen> {
  final CollaborationService _collabService = CollaborationService();
  final WebdavSyncService _webdavService = WebdavSyncService();

  String _base64Payload = '';
  bool _loadingPayload = true;
  bool _processingImport = false;

  // WebDAV config
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _testingConnection = false;
  bool _webdavConfigured = false;

  // Manual import
  final TextEditingController _importController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generatePayload();
    _loadWebdavConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userController.dispose();
    _passController.dispose();
    _importController.dispose();
    super.dispose();
  }

  Future<void> _generatePayload() async {
    try {
      final payload = await _collabService.exportDeckToBase64(widget.deckId);
      setState(() {
        _base64Payload = payload;
        _loadingPayload = false;
      });
    } catch (_) {
      setState(() {
        _loadingPayload = false;
      });
    }
  }

  Future<void> _loadWebdavConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = prefs.getString('webdav_url') ?? '';
      _userController.text = prefs.getString('webdav_username') ?? '';
      _passController.text = prefs.getString('webdav_password') ?? '';
      _webdavConfigured = _urlController.text.isNotEmpty;
    });
  }

  Future<void> _saveWebdavConfig() async {
    setState(() {
      _testingConnection = true;
    });

    final success = await _webdavService.testConnection(
      _urlController.text.trim(),
      _userController.text.trim(),
      _passController.text.trim(),
    );

    setState(() {
      _testingConnection = false;
    });

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('webdav_url', _urlController.text.trim());
      await prefs.setString('webdav_username', _userController.text.trim());
      await prefs.setString('webdav_password', _passController.text.trim());
      setState(() {
        _webdavConfigured = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WebDAV credentials verified and saved successfully!'), backgroundColor: AppColors.primaryContainer),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed. Please check your WebDAV credentials.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _backupToWebdav() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backing up deck to WebDAV...')));
    final success = await _webdavService.syncUpload(
      'deck_${widget.deckId}.json',
      _base64Payload,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deck successfully backed up to WebDAV!'), backgroundColor: AppColors.primaryContainer),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup failed. Check network or server configuration.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _importFromBase64() async {
    final rawText = _importController.text.trim();
    if (rawText.isEmpty) return;

    setState(() {
      _processingImport = true;
    });

    try {
      final importedDeck = await _collabService.importDeckFromBase64(rawText);
      _importController.clear();
      setState(() {
        _processingImport = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported "${importedDeck.name}" successfully!'), backgroundColor: AppColors.primaryContainer),
        );
        // Navigate to the imported deck
        AppRouter.goToDeckDetail(context, importedDeck.id, importedDeck.name);
      }
    } catch (e) {
      setState(() {
        _processingImport = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import deck: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
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
        title: const Text('Collaboration & Sharing', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Direct Share QR & String
            Text('QR CODE DECK SHARE', style: textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.primaryContainer)),
            const SizedBox(height: 12),
            _buildShareCard(),
            const SizedBox(height: 32),

            // Section 2: Import Deck
            Text('IMPORT SHARED DECK', style: textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.primaryContainer)),
            const SizedBox(height: 12),
            _buildImportCard(),
            const SizedBox(height: 32),

            // Section 3: WebDAV Sync Setup
            Text('DECENTRALIZED WEBDAV SYNC', style: textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.primaryContainer)),
            const SizedBox(height: 12),
            _buildWebdavCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCard() {
    final textTheme = Theme.of(context).textTheme;

    if (_loadingPayload) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer));
    }

    if (_base64Payload.isEmpty) {
      return const Center(child: Text('Error generating deck share package.'));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: _base64Payload,
              version: QrVersions.auto,
              size: 200,
              gapless: false,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan with another device to import "${widget.deckName}" instantly.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: AppColors.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _base64Payload));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share link copied to clipboard!')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('COPY SHARE STRING'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _importController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Paste the base64 share string here...',
              hintStyle: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.4)),
              filled: true,
              fillColor: AppColors.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: AppColors.onSurface, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _processingImport ? null : _importFromBase64,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _processingImport
                  ? const CircularProgressIndicator(color: AppColors.onPrimaryContainer)
                  : const Text('IMPORT DECK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebdavCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'WebDAV Server URL',
              labelStyle: TextStyle(color: AppColors.primaryContainer),
              hintText: 'https://nextcloud.example.com/remote.php/dav/files/user/',
            ),
            style: const TextStyle(color: AppColors.onSurface),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userController,
            decoration: const InputDecoration(
              labelText: 'Username',
              labelStyle: TextStyle(color: AppColors.primaryContainer),
            ),
            style: const TextStyle(color: AppColors.onSurface),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: AppColors.primaryContainer),
            ),
            style: const TextStyle(color: AppColors.onSurface),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _testingConnection ? null : _saveWebdavConfig,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryContainer,
                    side: const BorderSide(color: AppColors.primaryContainer),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _testingConnection
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryContainer))
                      : const Text('VERIFY & SAVE'),
                ),
              ),
              if (_webdavConfigured) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _backupToWebdav,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('BACKUP NOW'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
