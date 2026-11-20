import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/start_screen.dart';
import 'texte.dart';
import 'theme.dart';

void main() {
  Texte.english = PlatformDispatcher.instance.locale.languageCode != 'de';
  runApp(const ProviderScope(child: WanderrucksackApp()));
}

class WanderrucksackApp extends StatelessWidget {
  const WanderrucksackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Texte.appName,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const StartScreen(),
    );
  }
}
