import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/providers/chat_providers.dart';
import 'package:recall_app/models/chat_message.dart';
import 'widgets/chat_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String deckId;
  final String deckName;

  const ChatScreen({
    Key? key,
    required this.deckId,
    required this.deckName,
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    setState(() {
      _isSending = true;
    });

    _scrollToBottom();

    try {
      final tutorService = ref.read(aiTutorServiceProvider);
      await tutorService.sendMessage(widget.deckId, text);
      ref.invalidate(chatHistoryProvider(widget.deckId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get reply: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text('Clear Chat?', style: TextStyle(fontFamily: 'Manrope', color: AppColors.onSurface)),
        content: const Text('This will delete the conversation history for this deck.', style: TextStyle(fontFamily: 'Manrope', color: AppColors.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.outline)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final tutorService = ref.read(aiTutorServiceProvider);
      await tutorService.clearHistory(widget.deckId);
      ref.invalidate(chatHistoryProvider(widget.deckId));
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGold = Color(0xFFE3C36C);
    const surfaceContainer = Color(0xFF21201B);
    const onSurface = Color(0xFFE7E2DA);
    const onSurfaceVariant = Color(0xFFCFC5B3);

    final historyAsync = ref.watch(chatHistoryProvider(widget.deckId));

    // Scroll to bottom after loading data
    historyAsync.whenData((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Study AI Tutor',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
            ),
            Text(
              'Deck: ${widget.deckName}',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                color: onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            onPressed: _clearChat,
            tooltip: 'Clear Chat History',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: primaryGold)),
                error: (err, __) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 64, color: primaryGold),
                            const SizedBox(height: 16),
                            const Text(
                              'Start your study session',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ask the tutor to explain cards, generate mock questions, or clarify memory concepts.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13,
                                color: onSurfaceVariant.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(message: messages[index]);
                    },
                  );
                },
              ),
            ),
            if (_isSending)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: primaryGold),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tutor is thinking...',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        color: onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            // Bottom Message Input Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: surfaceContainer,
                border: Border(
                  top: BorderSide(color: onSurface.withOpacity(0.05)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: onSurface, fontFamily: 'Manrope'),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type a message to your tutor...',
                        hintStyle: TextStyle(color: onSurfaceVariant.withOpacity(0.4), fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: primaryGold),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
