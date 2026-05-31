import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/encryption_service.dart';
import '../services/steganography_service.dart';

enum PasswordStrength { none, weak, medium, strong }

class EncryptScreen extends StatefulWidget {
  const EncryptScreen({super.key});

  @override
  State<EncryptScreen> createState() => _EncryptScreenState();
}

class _EncryptScreenState extends State<EncryptScreen> {
  final _textController = TextEditingController();
  final _passwordController = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;
  bool _isProcessing = false;
  String? _statusMessage;
  bool _isSuccess = false;
  String? _savedFilePath;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImagePath = picked.path;
      });
    }
  }

  Future<void> _encryptAndHide() async {
    if (_textController.text.isEmpty) {
      _showStatus('Enter text to encrypt', false);
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showStatus('Enter a password', false);
      return;
    }
    if (_selectedImageBytes == null) {
      _showStatus('Pick a cover image first', false);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final encrypted = EncryptionService.encryptText(
        _textController.text,
        _passwordController.text,
      );

      final stegoImageBytes = SteganographyService.hideTextInImage(
        _selectedImageBytes!,
        encrypted,
      );

      final hash = EncryptionService.generateHash(stegoImageBytes);

      final dir = await getDownloadsDirectory();
      final fileName =
          'cryptovault_${DateTime.now().millisecondsSinceEpoch}.png';
      final outputFile = File('${dir!.path}/$fileName');
      await outputFile.writeAsBytes(stegoImageBytes);

      _showStatus(
        'Done! Saved as $fileName\nHash: ${hash.substring(0, 20)}...',
        true,
      );
      _savedFilePath = outputFile.path;
    } catch (e) {
      _showStatus('Error: ${e.toString()}', false);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showStatus(String message, bool success) {
    setState(() {
      _statusMessage = message;
      _isSuccess = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text(
          'Encrypt & Hide',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Secret Text'),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Type your secret message...'),
            ),
            const SizedBox(height: 20),

            _label('Password'),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Enter encryption password...'),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 8),
            _PasswordStrengthBar(password: _passwordController.text),
            const SizedBox(height: 20),

            _label('Cover Image'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedImageBytes != null
                        ? const Color(0xFF6C63FF)
                        : Colors.white12,
                  ),
                ),
                child: _selectedImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            color: Colors.white24,
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap to pick cover image',
                            style: TextStyle(color: Colors.white24),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _encryptAndHide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Encrypt & Hide',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            if (_statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? const Color(0xFF00C896).withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSuccess
                        ? const Color(0xFF00C896).withOpacity(0.4)
                        : Colors.red.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _isSuccess
                        ? const Color(0xFF00C896)
                        : Colors.redAccent,
                    fontSize: 13,
                  ),
                ),
              ),

            if (_savedFilePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Share.shareXFiles([
                        XFile(_savedFilePath!),
                      ], text: 'Shared via CryptoVault');
                    },
                    icon: const Icon(Icons.share, color: Color(0xFF6C63FF)),
                    label: const Text(
                      'Share Stego Image',
                      style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6C63FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white60,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white24),
    filled: true,
    fillColor: const Color(0xFF1A1A1A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white12),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF6C63FF)),
    ),
  );
}

class _PasswordStrengthBar extends StatelessWidget {
  final String password;

  const _PasswordStrengthBar({required this.password});

  PasswordStrength _getStrength() {
    if (password.isEmpty) return PasswordStrength.none;
    if (password.length < 6) return PasswordStrength.weak;

    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    bool isLong = password.length >= 12;

    int score = [
      hasUpper,
      hasLower,
      hasDigit,
      hasSpecial,
      isLong,
    ].where((e) => e).length;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _getStrength();
    if (strength == PasswordStrength.none) return const SizedBox.shrink();

    final labels = {
      PasswordStrength.weak: 'Weak',
      PasswordStrength.medium: 'Medium',
      PasswordStrength.strong: 'Strong',
    };

    final colors = {
      PasswordStrength.weak: Colors.redAccent,
      PasswordStrength.medium: Colors.orangeAccent,
      PasswordStrength.strong: const Color(0xFF00C896),
    };

    final fills = {
      PasswordStrength.weak: 1,
      PasswordStrength.medium: 2,
      PasswordStrength.strong: 3,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (index) {
            final filled = index < (fills[strength] ?? 0);
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                height: 4,
                decoration: BoxDecoration(
                  color: filled ? colors[strength] : Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          labels[strength] ?? '',
          style: TextStyle(
            fontSize: 11,
            color: colors[strength],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
