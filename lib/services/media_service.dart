import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/media_attachment.dart';
import '../core/database/database_helper.dart';

class MediaService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> getMediaDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(docDir.path, 'media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir.path;
  }

  Future<MediaAttachment> saveMedia(String cardId, File file, MediaType type) async {
    final mediaDirPath = await getMediaDirectory();
    final originalName = p.basename(file.path);
    final ext = p.extension(file.path);
    final id = const Uuid().v4();
    final localFileName = '$id$ext';
    final localPath = p.join(mediaDirPath, localFileName);

    // Copy file to local media path
    await file.copy(localPath);

    final sizeBytes = await file.length();
    final attachment = MediaAttachment(
      id: id,
      cardId: cardId,
      type: type,
      fileName: originalName,
      localPath: localPath,
      sizeBytes: sizeBytes,
      createdAt: DateTime.now(),
    );

    // Save metadata to database
    final db = await _dbHelper.database;
    await db.insert('media_attachments', attachment.toMap());

    return attachment;
  }

  Future<List<MediaAttachment>> getMediaForCard(String cardId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'media_attachments',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
    return maps.map((map) => MediaAttachment.fromMap(map)).toList();
  }

  Future<void> deleteMedia(String mediaId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'media_attachments',
      where: 'id = ?',
      whereArgs: [mediaId],
    );
    if (maps.isEmpty) return;

    final attachment = MediaAttachment.fromMap(maps.first);
    final file = File(attachment.localPath);
    if (await file.exists()) {
      await file.delete();
    }

    await db.delete(
      'media_attachments',
      where: 'id = ?',
      whereArgs: [mediaId],
    );
  }
}
