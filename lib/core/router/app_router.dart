import 'package:flutter/material.dart';
import 'package:recall_app/models/card.dart';
import 'package:recall_app/features/deck/deck_detail_screen.dart';
import 'package:recall_app/features/deck/deck_form_screen.dart';
import 'package:recall_app/features/card/card_form_screen.dart';
import 'package:recall_app/features/settings/settings_screen.dart';
import 'package:recall_app/features/review/review_session_screen.dart';
import 'package:recall_app/features/stats/stats_screen.dart';
import 'package:recall_app/features/ai/ai_generate_screen.dart';
import 'package:recall_app/features/chat/chat_screen.dart';

class AppRouter {
  static void goToReviewSession(BuildContext context, String deckId, String deckName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewSessionScreen(deckId: deckId, deckName: deckName),
      ),
    );
  }

  static void goToDeckDetail(BuildContext context, String deckId, String deckName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeckDetailScreen(deckId: deckId, deckName: deckName),
      ),
    );
  }

  static void goToCreateDeck(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeckFormScreen(),
      ),
    );
  }

  static void goToCreateCard(BuildContext context, String deckId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardFormScreen(deckId: deckId),
      ),
    );
  }

  static void goToEditCard(BuildContext context, FlashCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardFormScreen(card: card),
      ),
    );
  }

  static void goToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  static void goToStats(BuildContext context, String deckId, String deckName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsScreen(deckId: deckId, deckName: deckName),
      ),
    );
  }

  static void goToAiGenerate(BuildContext context, String deckId, String deckName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiGenerateScreen(deckId: deckId, deckName: deckName),
      ),
    );
  }

  static void goToChat(BuildContext context, String deckId, String deckName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(deckId: deckId, deckName: deckName),
      ),
    );
  }
}
