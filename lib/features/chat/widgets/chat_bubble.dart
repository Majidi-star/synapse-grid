import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../../../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;

    const primaryGold = Color(0xFFE3C36C);
    const bubbleUser = primaryGold;
    const textUser = Color(0xFF15130F);
    const bubbleTutor = Color(0xFF2C2A25);
    const textTutor = Color(0xFFE7E2DA);
    const onSurfaceVariant = Color(0xFFCFC5B3);

    final timeStr = DateFormat('jm').format(message.createdAt);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? bubbleUser : bubbleTutor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser ? Colors.transparent : const Color(0xFFE6E1D9).withOpacity(0.05),
                ),
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        color: textUser,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 15,
                          color: textTutor,
                          height: 1.5,
                        ),
                        code: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          backgroundColor: Colors.black.withOpacity(0.3),
                          color: primaryGold,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        listBullet: const TextStyle(color: primaryGold),
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                timeStr,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 10,
                  color: onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
