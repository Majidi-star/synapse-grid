import 'package:flutter/material.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'ai_providers_screen.dart';
import 'mcp_connections_screen.dart';
import '../import_export/import_screen.dart';
import '../import_export/export_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _targetRetention = 0.90;
  final int _dailyNewCards = 20;
  final int _dailyReviewLimit = 200;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _buildSectionHeader(context, 'SCHEDULING'),
          _buildTile(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target Retention: ${(_targetRetention * 100).toInt()}%',
                  style: const TextStyle(color: AppColors.onSurface),
                ),
                Slider(
                  value: _targetRetention,
                  min: 0.80,
                  max: 0.95,
                  divisions: 15,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.surfaceContainerHighest,
                  onChanged: (value) {
                    setState(() => _targetRetention = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildTile(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily New Cards', style: TextStyle(color: AppColors.onSurface)),
                Text('$_dailyNewCards', style: const TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildTile(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily Review Limit', style: TextStyle(color: AppColors.onSurface)),
                Text('$_dailyReviewLimit', style: const TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'AI COGNITIVE ASSISTANCE'),
          _buildTile(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Manage AI Provider Profiles', style: TextStyle(color: AppColors.onSurface)),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.outline),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AiProvidersScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildTile(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Local MCP Ingestion Sources', style: TextStyle(color: AppColors.onSurface)),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.outline),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const McpConnectionsScreen()),
              );
            },
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'DATA'),
          _buildTile(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Import Anki Deck (.apkg)', style: TextStyle(color: AppColors.onSurface)),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.outline),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnkiImportScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildTile(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Export to Anki (.apkg)', style: TextStyle(color: AppColors.onSurface)),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.outline),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnkiExportScreen()),
              );
            },
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'ABOUT'),
          _buildTile(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Version 0.1.0', style: TextStyle(color: AppColors.onSurface)),
                const SizedBox(height: 4),
                Text(
                  'Built with ♥ and science',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.outline,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTile({required Widget child, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        ),
        child: child,
      ),
    );
  }
}
