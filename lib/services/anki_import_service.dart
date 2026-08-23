import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:recall_app/models/card.dart';
import 'package:recall_app/models/deck.dart';
import 'card_service.dart';
import 'deck_service.dart';
import 'media_service.dart';
import '../models/media_attachment.dart';

class AnkiImportResult {
  final int decksImported;
  final int cardsImported;
  final int mediaImported;

  AnkiImportResult({
    required this.decksImported,
    required this.cardsImported,
    required this.mediaImported,
  });
}

class AnkiImportService {
  final CardService _cardService = CardService();
  final DeckService _deckService = DeckService();
  final MediaService _mediaService = MediaService();

  Future<AnkiImportResult> importApkg(String filePath) async {
    final tempDir = await getTemporaryDirectory();
    final importDir = Directory(p.join(tempDir.path, 'anki_import_${DateTime.now().millisecondsSinceEpoch}'));
    await importDir.create(recursive: true);

    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        final outFile = File(p.join(importDir.path, filename));
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(data);
      }
    }

    String dbPath = p.join(importDir.path, 'collection.anki21');
    if (!await File(dbPath).exists()) {
      dbPath = p.join(importDir.path, 'collection.anki2');
    }

    if (!await File(dbPath).exists()) {
      throw Exception('collection.anki21 or collection.anki2 not found in apkg');
    }

    final ankiDb = await openDatabase(dbPath);

    final List<Map<String, dynamic>> colRows = await ankiDb.query('col');
    if (colRows.isEmpty) {
      await ankiDb.close();
      throw Exception('col table is empty in Anki database');
    }

    final col = colRows.first;
    final Map<String, dynamic> decksJson = jsonDecode(col['decks'] as String);
    final Map<String, dynamic> modelsJson = jsonDecode(col['models'] as String);

    final Map<String, String> ankiDeckToLocalDeck = {};

    int decksImportedCount = 0;
    for (final entry in decksJson.entries) {
      final deckData = entry.value as Map<String, dynamic>;
      final String deckName = deckData['name'] as String;
      if (deckName == 'Default' && decksJson.length > 1) continue;

      final deckId = const Uuid().v4();
      final localDeck = Deck(
        id: deckId,
        name: deckName,
        description: 'Imported from Anki',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _deckService.createDeck(localDeck);
      ankiDeckToLocalDeck[entry.key] = deckId;
      decksImportedCount++;
    }

    if (ankiDeckToLocalDeck.isEmpty && decksJson.isNotEmpty) {
      final firstKey = decksJson.keys.first;
      final deckId = const Uuid().v4();
      await _deckService.createDeck(Deck(
        id: deckId,
        name: decksJson[firstKey]['name'] as String,
        description: 'Imported from Anki',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      ankiDeckToLocalDeck[firstKey] = deckId;
      decksImportedCount++;
    }

    final List<Map<String, dynamic>> cardRows = await ankiDb.rawQuery('''
      SELECT c.id as card_id, c.nid as note_id, c.did as deck_id, c.ord,
             n.flds, n.mid as model_id
      FROM cards c
      JOIN notes n ON c.nid = n.id
    ''');

    int cardsImportedCount = 0;
    int mediaImportedCount = 0;

    final Map<String, dynamic> mediaMapping = {};
    final mediaFile = File(p.join(importDir.path, 'media'));
    if (await mediaFile.exists()) {
      try {
        final content = await mediaFile.readAsString();
        mediaMapping.addAll(jsonDecode(content) as Map<String, dynamic>);
      } catch (_) {}
    }

    for (final row in cardRows) {
      final ankiDeckId = (row['deck_id'] as num).toString();
      final localDeckId = ankiDeckToLocalDeck[ankiDeckId] ?? ankiDeckToLocalDeck.values.first;

      final String flds = row['flds'] as String;
      final List<String> fields = flds.split('\x1f');
      if (fields.isEmpty) continue;

      final modelId = (row['model_id'] as num).toString();
      final modelData = modelsJson[modelId] as Map<String, dynamic>?;
      final modelName = modelData?['name'] as String? ?? '';
      final isCloze = modelName.toLowerCase().contains('cloze');

      final cardType = isCloze ? CardType.cloze : CardType.basic;

      String front = fields[0];
      String back = fields.length > 1 ? fields[1] : '';

      front = _cleanHtml(front);
      back = _cleanHtml(back);

      final cardId = const Uuid().v4();
      final card = FlashCard(
        id: cardId,
        deckId: localDeckId,
        frontText: front,
        backText: back,
        cardType: cardType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _cardService.createCard(card);
      cardsImportedCount++;

      final mediaRefs = _scanMediaReferences(fields.join(' '));
      for (final ref in mediaRefs) {
        final mediaIndexKey = mediaMapping.entries
            .firstWhere((e) => e.value == ref, orElse: () => const MapEntry('', ''))
            .key;

        if (mediaIndexKey.isNotEmpty) {
          final sourcePath = p.join(importDir.path, mediaIndexKey);
          final sourceFile = File(sourcePath);
          if (await sourceFile.exists()) {
            final isAudio = ref.endsWith('.mp3') || ref.endsWith('.m4a') || ref.endsWith('.wav');
            final mediaType = isAudio ? MediaType.audio : MediaType.image;

            await _mediaService.saveMedia(cardId, sourceFile, mediaType);
            mediaImportedCount++;
          }
        }
      }
    }

    await ankiDb.close();
    await importDir.delete(recursive: true);

    return AnkiImportResult(
      decksImported: decksImportedCount,
      cardsImported: cardsImportedCount,
      mediaImported: mediaImportedCount,
    );
  }

  String _cleanHtml(String html) {
    var text = html.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    return text.trim();
  }

  List<String> _scanMediaReferences(String text) {
    final List<String> refs = [];
    final imgRegex = RegExp(r'src="([^"]+)"|src=\x27([^\x27]+)\x27');
    for (final match in imgRegex.allMatches(text)) {
      final filename = match.group(1) ?? match.group(2);
      if (filename != null) {
        refs.add(filename);
      }
    }
    final soundRegex = RegExp(r'\[sound:(.*?)\]');
    for (final match in soundRegex.allMatches(text)) {
      if (match.group(1) != null) {
        refs.add(match.group(1)!);
      }
    }
    return refs;
  }
}
