import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CryptoVaultApp());
}

class CryptoVaultApp extends StatelessWidget {
  const CryptoVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CryptoVault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'monospace',
      ),
      home: const HomeScreen(),
    );
  }
}