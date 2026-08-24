import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recall_app/core/database/database_helper.dart';

import '../models/ai_provider.dart';

class DynamicAiService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<AiProvider?> getActiveProvider() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ai_providers',
      where: 'is_active = 1',
    );
    if (maps.isEmpty) return null;
    return AiProvider.fromMap(maps.first);
  }

  Future<void> saveProvider(AiProvider provider) async {
    final db = await _dbHelper.database;
    if (provider.isActive) {
      await db.update('ai_providers', {'is_active': 0});
    }
    final existing = await db.query(
      'ai_providers',
      where: 'id = ?',
      whereArgs: [provider.id],
    );
    if (existing.isEmpty) {
      await db.insert('ai_providers', provider.toMap());
    } else {
      await db.update(
        'ai_providers',
        provider.toMap(),
        where: 'id = ?',
        whereArgs: [provider.id],
      );
    }
  }

  Future<List<AiProvider>> getAllProviders() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('ai_providers');
    return maps.map((m) => AiProvider.fromMap(m)).toList();
  }

  Future<void> deleteProvider(String id) async {
    final db = await _dbHelper.database;
    await db.delete('ai_providers', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> complete(String systemPrompt, String userMessage) async {
    final provider = await getActiveProvider();
    if (provider == null) {
      throw Exception(
        'No active AI Provider configured. Please set one up in Settings.',
      );
    }

    final apiKey = provider.apiKey ?? '';
    final model = provider.selectedModel ?? '';
    final type = provider.providerType;
    final baseUrl = provider.baseUrl;

    if (type == 'gemini') {
      final selectedModel = model.isNotEmpty ? model : 'gemini-1.5-flash';
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$selectedModel:generateContent?key=$apiKey',
      );
      final response = await _postWithRetry(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': userMessage},
              ],
            },
          ],
          'systemInstruction': {
            'parts': [
              {'text': systemPrompt},
            ],
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Gemini completion failed: ${response.body}');
      }
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    } else if (type == 'openai' || type == 'ollama') {
      final urlStr = baseUrl != null && baseUrl.isNotEmpty
          ? baseUrl
          : 'https://api.openai.com/v1';
      final endpoint = Uri.parse('$urlStr/chat/completions');
      final selectedModel = model.isNotEmpty
          ? model
          : (type == 'openai' ? 'gpt-4o-mini' : 'llama3');

      final headers = {
        'Content-Type': 'application/json',
        if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      };

      final response = await _postWithRetry(
        endpoint,
        headers: headers,
        body: jsonEncode({
          'model': selectedModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('AI completion failed: ${response.body}');
      }
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else if (type == 'anthropic') {
      final urlStr = baseUrl != null && baseUrl.isNotEmpty
          ? baseUrl
          : 'https://api.anthropic.com/v1';
      final endpoint = Uri.parse('$urlStr/messages');
      final selectedModel = model.isNotEmpty
          ? model
          : 'claude-3-5-sonnet-20241022';

      final response = await _postWithRetry(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': selectedModel,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 4000,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Anthropic completion failed: ${response.body}');
      }
      final data = jsonDecode(response.body);
      return data['content'][0]['text'] as String;
    }

    throw Exception('Unsupported provider type: $type');
  }

  Future<void> testConnection(AiProvider provider) async {
    final apiKey = provider.apiKey ?? '';
    final type = provider.providerType;
    final model = provider.selectedModel ?? '';
    final baseUrl = provider.baseUrl;

    if (type == 'gemini') {
      final selectedModel = model.isNotEmpty ? model : 'gemini-1.5-flash';
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$selectedModel:generateContent?key=$apiKey',
      );
      final response = await _postWithRetry(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Hello'},
              ],
            },
          ],
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Gemini connection test failed: ${response.body}');
      }
    } else if (type == 'openai' || type == 'ollama') {
      final urlStr = baseUrl != null && baseUrl.isNotEmpty
          ? baseUrl
          : 'https://api.openai.com/v1';
      final endpoint = Uri.parse('$urlStr/chat/completions');
      final selectedModel = model.isNotEmpty
          ? model
          : (type == 'openai' ? 'gpt-4o-mini' : 'llama3');

      final headers = {
        'Content-Type': 'application/json',
        if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      };

      final response = await _postWithRetry(
        endpoint,
        headers: headers,
        body: jsonEncode({
          'model': selectedModel,
          'messages': [
            {'role': 'user', 'content': 'Hello'},
          ],
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Connection test failed: ${response.body}');
      }
    } else if (type == 'anthropic') {
      final urlStr = baseUrl != null && baseUrl.isNotEmpty
          ? baseUrl
          : 'https://api.anthropic.com/v1';
      final endpoint = Uri.parse('$urlStr/messages');
      final selectedModel = model.isNotEmpty
          ? model
          : 'claude-3-5-sonnet-20241022';

      final response = await _postWithRetry(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': selectedModel,
          'messages': [
            {'role': 'user', 'content': 'Hello'},
          ],
          'max_tokens': 10,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Anthropic connection test failed: ${response.body}');
      }
    }
  }

  static SharedPreferences? _prefs;
  Map<String, List<String>> _modelsCache = {};

  static Future<void> initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  DynamicAiService() {
    _loadCache();
  }

  void _loadCache() {
    if (_prefs != null) {
      final cacheStr = _prefs!.getString('modelsCache');
      if (cacheStr != null) {
        try {
          final decoded = jsonDecode(cacheStr) as Map<String, dynamic>;
          _modelsCache = decoded.map(
            (k, v) => MapEntry(k, List<String>.from(v)),
          );
        } catch (_) {}
      }
    }
  }

  Future<void> _saveCache() async {
    if (_prefs != null) {
      await _prefs!.setString('modelsCache', jsonEncode(_modelsCache));
    }
  }

  List<String> getCachedModels(String type, String apiKey, String? baseUrl) {
    final cacheKey = '$type-$apiKey-$baseUrl';
    return _modelsCache[cacheKey] ?? [];
  }

  Future<http.Response> _postWithRetry(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    for (int i = 0; i < 2; i++) {
      try {
        return await http.post(url, headers: headers, body: body);
      } catch (e) {
        if (i == 1) rethrow;
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    throw Exception('Unreachable');
  }

  Future<http.Response> _getWithRetry(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    for (int i = 0; i < 2; i++) {
      try {
        return await http.get(url, headers: headers);
      } catch (e) {
        if (i == 1) rethrow;
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    throw Exception('Unreachable');
  }

  Future<List<String>> fetchAvailableModels(
    String type,
    String apiKey,
    String? baseUrl,
  ) async {
    final cacheKey = '$type-$apiKey-$baseUrl';
    if (_modelsCache.containsKey(cacheKey)) {
      return _modelsCache[cacheKey]!;
    }
    try {
      if (type == 'gemini') {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
        );
        final response = await _getWithRetry(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final models = data['models'] as List<dynamic>?;
          if (models != null) {
            _modelsCache[cacheKey] = models
                .map((m) => (m['name'] as String).replaceFirst('models/', ''))
                .where((name) => name.contains('gemini'))
                .toList();
            await _saveCache();
            return _modelsCache[cacheKey]!;
          }
        }
      } else if (type == 'openai' || type == 'ollama') {
        final urlStr = baseUrl != null && baseUrl.isNotEmpty
            ? baseUrl
            : 'https://api.openai.com/v1';
        final endpoint = Uri.parse('$urlStr/models');
        final headers = {
          'Content-Type': 'application/json',
          if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
        };
        final response = await _getWithRetry(endpoint, headers: headers);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final models = data['data'] as List<dynamic>?;
          if (models != null) {
            _modelsCache[cacheKey] = models
                .map((m) => m['id'] as String)
                .toList();
            await _saveCache();
            return _modelsCache[cacheKey]!;
          }
        }
      } else if (type == 'anthropic') {
        final urlStr = baseUrl != null && baseUrl.isNotEmpty
            ? baseUrl
            : 'https://api.anthropic.com/v1';
        final endpoint = Uri.parse('$urlStr/models');
        final response = await _getWithRetry(
          endpoint,
          headers: {'x-api-key': apiKey, 'anthropic-version': '2023-06-01'},
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final models = data['data'] as List<dynamic>?;
          if (models != null) {
            _modelsCache[cacheKey] = models
                .map((m) => m['id'] as String)
                .toList();
            await _saveCache();
            return _modelsCache[cacheKey]!;
          }
        } else {
          // Fallback if anthropic models endpoint is restricted or unsupported
          _modelsCache[cacheKey] = [
            'claude-3-5-sonnet-20241022',
            'claude-3-5-haiku-20241022',
            'claude-3-opus-20240229',
            'claude-3-sonnet-20240229',
            'claude-3-haiku-20240307',
          ];
          await _saveCache();
          return _modelsCache[cacheKey]!;
        }
      }
    } catch (e) {
      // Return empty list on failure, user can still type manually
    }
    return [];
  }
}
