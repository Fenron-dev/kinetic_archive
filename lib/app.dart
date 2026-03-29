import 'package:flutter/material.dart';
import 'theme/theme.dart';
import 'screens/shell.dart';

class KineticArchiveApp extends StatelessWidget {
  const KineticArchiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Kinetic Archive',
      theme: buildKaTheme(),
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}
