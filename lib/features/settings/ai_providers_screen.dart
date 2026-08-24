import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/providers/ai_providers.dart';
import 'package:recall_app/models/ai_provider.dart';
import 'package:recall_app/services/ai_service.dart';
import 'package:uuid/uuid.dart';

class AiProvidersScreen extends ConsumerWidget {
  const AiProvidersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryGold = Color(0xFFE3C36C);
    const surfaceContainer = Color(0xFF21201B);
    const onSurface = Color(0xFFE7E2DA);
    const onSurfaceVariant = Color(0xFFCFC5B3);

    final listAsync = ref.watch(aiProvidersListProvider);

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
          'AI Provider Profiles',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: listAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: primaryGold)),
        error: (err, __) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (providers) {
          if (providers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.api_rounded,
                    size: 64,
                    color: onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Providers Added',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      color: onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(context, ref, null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGold,
                      foregroundColor: AppColors.background,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Add Provider Profile',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: provider.isActive
                        ? primaryGold
                        : onSurface.withOpacity(0.05),
                    width: provider.isActive ? 1.5 : 1.0,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          provider.name,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (provider.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: primaryGold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Type: ${provider.providerType.toUpperCase()} | Model: ${provider.selectedModel ?? "Default"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        color: onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () =>
                            _showAddEditDialog(context, ref, provider),
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: onSurfaceVariant,
                        ),
                        tooltip: 'Edit',
                      ),
                      if (!provider.isActive)
                        IconButton(
                          onPressed: () async {
                            final dynamicAiService = ref.read(
                              dynamicAiServiceProvider,
                            );
                            final updated = provider.copyWith(isActive: true);
                            await dynamicAiService.saveProvider(updated);
                            ref.invalidate(aiProvidersListProvider);
                            ref.invalidate(activeAiProvider);
                          },
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: onSurfaceVariant,
                          ),
                          tooltip: 'Set Active',
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGold,
        foregroundColor: AppColors.background,
        onPressed: () => _showAddEditDialog(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context,
    WidgetRef ref,
    AiProvider? existing,
  ) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final typeController = TextEditingController(
      text: existing?.providerType ?? 'gemini',
    );
    final baseUrlController = TextEditingController(
      text: existing?.baseUrl ?? '',
    );
    final apiKeyController = TextEditingController(
      text: existing?.apiKey ?? '',
    );
    final modelController = TextEditingController(
      text: existing?.selectedModel ?? '',
    );
    bool isActive = existing?.isActive ?? false;
    String? testMessage;
    bool isTestError = false;
    bool isTesting = false;
    final dynamicAiService = ref.read(dynamicAiServiceProvider);
    List<String> availableModels = dynamicAiService.getCachedModels(
      existing?.providerType ?? 'gemini',
      existing?.apiKey ?? '',
      existing?.baseUrl,
    );
    bool isFetchingModels = false;
    final scrollController = ScrollController();

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceContainerHigh,
              title: Text(
                existing == null
                    ? 'Add AI Provider Profile'
                    : 'Edit AI Provider Profile',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  color: AppColors.onSurface,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Scrollbar(
                        controller: scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                    controller: nameController,
                                    style: const TextStyle(
                                      color: AppColors.onSurface,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Profile Name (e.g. Gemini Free)',
                                    ),
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Name required'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: typeController.text,
                                    dropdownColor:
                                        AppColors.surfaceContainerHigh,
                                    focusColor: Colors.transparent,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Provider Protocol Type',
                                      filled: true,
                                      fillColor: AppColors.surfaceContainerHigh,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'gemini',
                                        child: Text(
                                          'Google Gemini API',
                                          style: TextStyle(
                                            color: AppColors.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'openai',
                                        child: Text(
                                          'OpenAI API',
                                          style: TextStyle(
                                            color: AppColors.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'anthropic',
                                        child: Text(
                                          'Anthropic Claude API',
                                          style: TextStyle(
                                            color: AppColors.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'ollama',
                                        child: Text(
                                          'Ollama / Local (OpenAI format)',
                                          style: TextStyle(
                                            color: AppColors.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setDialogState(() {
                                          typeController.text = val;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: baseUrlController,
                                    style: const TextStyle(
                                      color: AppColors.onSurface,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Base Endpoint URL (optional)',
                                      hintText:
                                          'e.g. http://localhost:11434/v1',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: apiKeyController,
                                    style: const TextStyle(
                                      color: AppColors.onSurface,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'API Authentication Key',
                                    ),
                                    obscureText: true,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Model Identifier Tag',
                                        style: TextStyle(
                                          color: AppColors.onSurface,
                                          fontSize: 14,
                                        ),
                                      ),
                                      IconButton(
                                        icon: isFetchingModels
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFFE3C36C),
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.sync_rounded,
                                                size: 20,
                                                color: Color(0xFFE3C36C),
                                              ),
                                        tooltip: 'Sync Models from Provider',
                                        onPressed: isFetchingModels
                                            ? null
                                            : () async {
                                                modelController.clear();
                                                setDialogState(() {
                                                  isFetchingModels = true;
                                                });
                                                final fetched =
                                                    await dynamicAiService
                                                        .fetchAvailableModels(
                                                          typeController.text,
                                                          apiKeyController.text,
                                                          baseUrlController
                                                              .text,
                                                        );
                                                setDialogState(() {
                                                  availableModels = fetched;
                                                  isFetchingModels = false;
                                                });
                                              },
                                      ),
                                    ],
                                  ),
                                  DropdownMenu<String>(
                                    key: ValueKey(availableModels.length),
                                    controller: modelController,
                                    expandedInsets: EdgeInsets.zero,
                                    enableFilter: true,
                                    requestFocusOnTap: true,
                                    hintText: 'Select a model',
                                    textStyle: const TextStyle(
                                      color: AppColors.onSurface,
                                    ),
                                    menuStyle: MenuStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                        AppColors.surfaceContainerHigh,
                                      ),
                                    ),
                                    dropdownMenuEntries: availableModels
                                        .map(
                                          (m) => DropdownMenuEntry(
                                            value: m,
                                            label: m,
                                          ),
                                        )
                                        .toList(),
                                    onSelected: (val) {
                                      if (val != null)
                                        modelController.text = val;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  SwitchListTile(
                                    title: const Text(
                                      'Set as Active Profile',
                                      style: TextStyle(
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    value: isActive,
                                    activeColor: const Color(0xFFE3C36C),
                                    onChanged: (val) {
                                      setDialogState(() {
                                        isActive = val;
                                      });
                                    },
                                  ),
                                  if (testMessage != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isTestError
                                            ? Colors.redAccent.withOpacity(0.1)
                                            : Colors.greenAccent.withOpacity(
                                                0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isTestError
                                              ? Colors.redAccent.withOpacity(
                                                  0.3,
                                                )
                                              : Colors.greenAccent.withOpacity(
                                                  0.3,
                                                ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isTestError
                                                ? Icons.error_outline_rounded
                                                : Icons
                                                      .check_circle_outline_rounded,
                                            color: isTestError
                                                ? Colors.redAccent
                                                : Colors.greenAccent,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              testMessage!,
                                              style: TextStyle(
                                                color: isTestError
                                                    ? Colors.redAccent
                                                    : Colors.greenAccent,
                                                fontSize: 12,
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
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (existing != null)
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: AppColors.surfaceContainerHigh,
                            title: const Text(
                              'Delete Provider',
                              style: TextStyle(color: AppColors.onSurface),
                            ),
                            content: const Text(
                              'Are you sure you want to delete this AI provider profile? This action cannot be undone.',
                              style: TextStyle(color: AppColors.onSurface),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: AppColors.onSurface),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true) {
                        final dynamicAiService = ref.read(
                          dynamicAiServiceProvider,
                        );
                        await dynamicAiService.deleteProvider(existing.id);
                        ref.invalidate(aiProvidersListProvider);
                        ref.invalidate(activeAiProvider);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                TextButton(
                  onPressed: isTesting
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() {
                              isTesting = true;
                              testMessage = null;
                            });
                            final dynamicAiService = ref.read(
                              dynamicAiServiceProvider,
                            );
                            final testProvider = AiProvider(
                              id: existing?.id ?? const Uuid().v4(),
                              name: nameController.text,
                              providerType: typeController.text,
                              baseUrl: baseUrlController.text,
                              apiKey: apiKeyController.text,
                              selectedModel: modelController.text,
                              isActive: isActive,
                              createdAt: DateTime.now(),
                            );
                            try {
                              await dynamicAiService.testConnection(
                                testProvider,
                              );
                              setDialogState(() {
                                isTesting = false;
                                isTestError = false;
                                testMessage =
                                    'Test successful! Connection established.';
                              });
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () {
                                  if (scrollController.hasClients) {
                                    scrollController.animateTo(
                                      scrollController.position.maxScrollExtent,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                },
                              );
                            } catch (e) {
                              setDialogState(() {
                                isTesting = false;
                                isTestError = true;
                                testMessage = 'Connection failed: $e';
                              });
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () {
                                  if (scrollController.hasClients) {
                                    scrollController.animateTo(
                                      scrollController.position.maxScrollExtent,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                },
                              );
                            }
                          }
                        },
                  child: isTesting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE3C36C),
                          ),
                        )
                      : const Text(
                          'Test Connection',
                          style: TextStyle(color: Color(0xFFE3C36C)),
                        ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final dynamicAiService = ref.read(
                        dynamicAiServiceProvider,
                      );
                      final provider = AiProvider(
                        id: existing?.id ?? const Uuid().v4(),
                        name: nameController.text,
                        providerType: typeController.text,
                        baseUrl: baseUrlController.text,
                        apiKey: apiKeyController.text,
                        selectedModel: modelController.text,
                        isActive: isActive,
                        createdAt: DateTime.now(),
                      );
                      await dynamicAiService.saveProvider(provider);
                      ref.invalidate(aiProvidersListProvider);
                      ref.invalidate(activeAiProvider);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE3C36C),
                    foregroundColor: AppColors.background,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
