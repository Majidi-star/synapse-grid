import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:shared_preferences/shared_preferences.dart';

class WebdavSyncService {
  Future<webdav.Client?> _getClient() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('webdav_url') ?? '';
    final username = prefs.getString('webdav_username') ?? '';
    final password = prefs.getString('webdav_password') ?? '';

    if (url.isEmpty) return null;

    final client = webdav.newClient(
      url,
      user: username,
      password: password,
    );
    return client;
  }

  Future<bool> testConnection(String url, String username, String password) async {
    try {
      final client = webdav.newClient(
        url,
        user: username,
        password: password,
      );
      // Attempt listing root to verify auth
      await client.readDir('/');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncUpload(String filename, String jsonContent) async {
    final client = await _getClient();
    if (client == null) return false;

    try {
      // Create nested directories on the WebDAV server if not existing
      try {
        await client.mkdir('/synap_sync');
      } catch (_) {
        // Directory might exist, ignore error
      }

      // Write to temp file locally
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, filename));
      await tempFile.writeAsString(jsonContent);

      // Upload file
      await client.writeFromFile(tempFile.path, '/synap_sync/$filename');
      
      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> syncDownload(String filename) async {
    final client = await _getClient();
    if (client == null) return null;

    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, filename));

      // Download file
      await client.read2File('/synap_sync/$filename', tempFile.path);

      if (!await tempFile.exists()) return null;
      final content = await tempFile.readAsString();

      // Clean up temp file
      await tempFile.delete();
      return content;
    } catch (_) {
      return null;
    }
  }
}
