import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:recall_app/core/database/database_helper.dart';

class AnkiExportService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> exportDeckToApkg(String deckId, String deckName) async {
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory(p.join(tempDir.path, 'anki_export_${DateTime.now().millisecondsSinceEpoch}'));
    await exportDir.create(recursive: true);

    // 1. Create a temporary SQLite database for Anki collection
    final dbPath = p.join(exportDir.path, 'collection.anki2');
    final ankiDb = await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE col (
          id INTEGER PRIMARY KEY,
          crt INTEGER,
          mod INTEGER,
          scm INTEGER,
          ver INTEGER,
          dats INTEGER,
          usn INTEGER,
          ls INTEGER,
          conf TEXT,
          models TEXT,
          decks TEXT,
          dconf TEXT,
          tags TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY,
          guid TEXT,
          mid INTEGER,
          mod INTEGER,
          usn INTEGER,
          tags TEXT,
          flds TEXT,
          sfld TEXT,
          csum INTEGER,
          flags INTEGER,
          data TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE cards (
          id INTEGER PRIMARY KEY,
          nid INTEGER,
          did INTEGER,
          ord INTEGER,
          mod INTEGER,
          usn INTEGER,
          type INTEGER,
          queue INTEGER,
          due INTEGER,
          ivl INTEGER,
          factor INTEGER,
          reps INTEGER,
          lapses INTEGER,
          "left" INTEGER,
          odue INTEGER,
          odid INTEGER,
          flags INTEGER,
          data TEXT
        )
      ''');
    });

    // 2. Populate "col" table
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final ankiDeckId = 1500000000000; // Large arbitrary ID
    final ankiModelId = 1600000000000;

    final decksJson = {
      "$ankiDeckId": {
        "id": ankiDeckId,
        "name": deckName,
        "mod": nowMs ~/ 1000,
        "desc": "Exported from Synap",
        "dyn": 0,
        "collapsed": false,
        "lrnToday": [0, 0],
        "revToday": [0, 0],
        "newToday": [0, 0],
        "timeToday": [0, 0],
        "conf": 1
      }
    };

    final modelsJson = {
      "$ankiModelId": {
        "id": ankiModelId,
        "name": "Synap Basic/Cloze Model",
        "flds": [
          {"name": "Front", "ord": 0, "sticky": false, "rtl": false, "font": "Arial", "size": 20},
          {"name": "Back", "ord": 1, "sticky": false, "rtl": false, "font": "Arial", "size": 20}
        ],
        "tmpls": [
          {
            "name": "Card 1",
            "ord": 0,
            "qfmt": "{{Front}}",
            "afmt": "{{FrontSide}}\n\n<hr id=answer>\n\n{{Back}}"
          }
        ],
        "mod": nowMs ~/ 1000,
        "type": 0
      }
    };

    await ankiDb.insert('col', {
      'id': 1,
      'crt': nowMs ~/ 1000,
      'mod': nowMs ~/ 1000,
      'scm': nowMs ~/ 1000,
      'ver': 11,
      'dats': 0,
      'usn': 0,
      'ls': 0,
      'conf': '{}',
      'models': jsonEncode(modelsJson),
      'decks': jsonEncode(decksJson),
      'dconf': '{}',
      'tags': '{}',
    });

    // 3. Fetch cards from local DB
    final localDb = await _dbHelper.database;
    final List<Map<String, dynamic>> cardRows = await localDb.query(
      'cards',
      where: 'deck_id = ?',
      whereArgs: [deckId],
    );

    final Map<String, String> mediaMap = {};
    int mediaIndex = 0;

    // 4. Populate notes and cards
    for (int i = 0; i < cardRows.length; i++) {
      final cardRow = cardRows[i];
      final cardIdStr = cardRow['id'] as String;
      final frontText = cardRow['front_text'] as String;
      final backText = cardRow['back_text'] as String;

      final noteId = 1700000000000 + i;
      final cardId = 1800000000000 + i;

      // Check media attachments for this card
      final List<Map<String, dynamic>> mediaRows = await localDb.query(
        'media_attachments',
        where: 'card_id = ?',
        whereArgs: [cardIdStr],
      );

      String formattedFront = frontText;
      for (final mediaRow in mediaRows) {
        final localPath = mediaRow['local_path'] as String;
        final originalName = mediaRow['file_name'] as String;
        final isAudio = originalName.endsWith('.mp3') || originalName.endsWith('.m4a');

        final File sourceFile = File(localPath);
        if (await sourceFile.exists()) {
          final String numberedFilename = "$mediaIndex";
          // Copy to temp directory as numbered filename
          await sourceFile.copy(p.join(exportDir.path, numberedFilename));
          mediaMap[numberedFilename] = originalName;

          if (isAudio) {
            formattedFront += " [sound:$originalName]";
          } else {
            formattedFront += ' <img src="$originalName">';
          }
          mediaIndex++;
        }
      }

      await ankiDb.insert('notes', {
        'id': noteId,
        'guid': const Uuid().v4().substring(0, 8),
        'mid': ankiModelId,
        'mod': nowMs ~/ 1000,
        'usn': -1,
        'tags': '',
        'flds': '$formattedFront\x1f$backText',
        'sfld': formattedFront,
        'csum': 0,
        'flags': 0,
        'data': '',
      });

      await ankiDb.insert('cards', {
        'id': cardId,
        'nid': noteId,
        'did': ankiDeckId,
        'ord': 0,
        'mod': nowMs ~/ 1000,
        'usn': -1,
        'type': 0,
        'queue': 0,
        'due': 0,
        'ivl': 0,
        'factor': 0,
        'reps': 0,
        'lapses': 0,
        'left': 0,
        'odue': 0,
        'odid': 0,
        'flags': 0,
        'data': '',
      });
    }

    await ankiDb.close();

    // 5. Create media mapping file in JSON
    final mediaFile = File(p.join(exportDir.path, 'media'));
    await mediaFile.writeAsString(jsonEncode(mediaMap));

    // 6. Zip everything into .apkg
    final archive = Archive();
    final col2File = File(p.join(exportDir.path, 'collection.anki2'));
    final col2Bytes = await col2File.readAsBytes();
    archive.addFile(ArchiveFile('collection.anki2', col2Bytes.length, col2Bytes));

    final mFile = File(p.join(exportDir.path, 'media'));
    final mBytes = await mFile.readAsBytes();
    archive.addFile(ArchiveFile('media', mBytes.length, mBytes));

    for (final entry in mediaMap.entries) {
      final file = File(p.join(exportDir.path, entry.key));
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
    }

    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);

    final outFilePath = p.join(tempDir.path, '${deckName.replaceAll(' ', '_')}.apkg');
    final outFile = File(outFilePath);
    await outFile.writeAsBytes(zipBytes!);

    // Clean up temporary folder
    await exportDir.delete(recursive: true);

    return outFilePath;
  }
}
