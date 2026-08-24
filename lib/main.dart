import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/app.dart';
import 'package:recall_app/core/platform/desktop_window_manager.dart';
import 'package:recall_app/services/local_clip_server.dart';
import 'package:recall_app/services/ai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DesktopWindowManager.initialize();
  await DynamicAiService.initPrefs();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    final clipServer = LocalClipServer();
    clipServer.start();
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1c1b16),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: SynapApp()));
}
