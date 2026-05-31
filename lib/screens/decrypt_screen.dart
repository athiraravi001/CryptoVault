import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/encryption_service.dart';
import '../services/steganography_service.dart';

class DecryptScreen extends StatefulWidget {
  const DecryptScreen({super.key});

  @override
  State<DecryptScreen> createState() => _DecryptScreenState();
}

class _DecryptScreenState extends State<DecryptScreen> {
  final _passwordController = TextEditingController();
  Uint8List? _selectedImageBytes;
  bool _isProcessing = false;
  String? _statusMessage;
  String? _decryptedText;
  bool _isSuccess = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _decryptedText = null;
        _statusMessage = null;
      });
    }
  }

  Future<void> _extractAndDecrypt() async {
    if (_selectedImageBytes == null) {
      _showStatus('Pick a stego image first', false);
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showStatus('Enter the password', false);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final hash = EncryptionService.generateHash(_selectedImageBytes!);

      final extractedEncrypted = SteganographyService.extractTextFromImage(
        _selectedImageBytes!,
      );

      final decrypted = EncryptionService.decryptText(
        extractedEncrypted,
        _passwordController.text,
      );

      setState(() {
        _decryptedText = decrypted;
        _isSuccess = true;
        _statusMessage =
            'Decrypted successfully!\nImage hash: ${hash.substring(0, 20)}...';
      });
    } catch (e) {
      _showStatus(
        'Failed — wrong password or image not from CryptoVault',
        false,
      );
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
          'Extract & Decrypt',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Stego Image'),
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
                        ? const Color(0xFF00C896)
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
                            Icons.image_search,
                            color: Colors.white24,
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap to pick stego image',
                            style: TextStyle(color: Colors.white24),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            _label('Password'),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Enter decryption password...'),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _extractAndDecrypt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Extract & Decrypt',
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

            if (_decryptedText != null) ...[
              const SizedBox(height: 20),
              _label('Decrypted Message'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                  ),
                ),
                child: SelectableText(
                  _decryptedText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _decryptedText!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        backgroundColor: Color(0xFF6C63FF),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.copy,
                    color: Color(0xFF6C63FF),
                    size: 18,
                  ),
                  label: const Text(
                    'Copy to Clipboard',
                    style: TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w500,
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
            ],
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
      borderSide: const BorderSide(color: Color(0xFF00C896)),
    ),
  );
}
