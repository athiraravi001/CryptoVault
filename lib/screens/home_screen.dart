import 'package:flutter/material.dart';
import 'encrypt_screen.dart';
import 'decrypt_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Icon(Icons.lock, color: Color(0xFF6C63FF), size: 40),
              const SizedBox(height: 16),
              const Text(
                'CryptoVault',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Encrypt & hide your secrets inside images.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 60),

              // Encrypt Card
              _ActionCard(
                icon: Icons.enhanced_encryption,
                title: 'Encrypt & Hide',
                subtitle: 'Encrypt text and hide it inside an image',
                color: const Color(0xFF6C63FF),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EncryptScreen()),
                ),
              ),
              const SizedBox(height: 16),

              // Decrypt Card
              _ActionCard(
                icon: Icons.no_encryption,
                title: 'Extract & Decrypt',
                subtitle: 'Extract hidden data from an image and decrypt it',
                color: const Color(0xFF00C896),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DecryptScreen()),
                ),
              ),

              const Spacer(),

              // Footer
              const Center(
                child: Text(
                  'AES-256 + LSB Steganography',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white24,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: color.withOpacity(0.6), size: 16),
          ],
        ),
      ),
    );
  }
}