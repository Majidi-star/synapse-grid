import 'package:flutter/material.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/features/home/home_screen.dart';

class SynapApp extends StatelessWidget {
  const SynapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synap',
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
