import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/encryption_service.dart';

class FileEncryptScreen extends StatefulWidget {
  const FileEncryptScreen({super.key});

  @override
  State<FileEncryptScreen> createState() => _FileEncryptScreenState();
}

class _FileEncryptScreenState extends State<FileEncryptScreen> {
  final _passwordController = TextEditingController();
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isProcessing = false;
  String? _statusMessage;
  bool _isSuccess = false;
  String? _savedFilePath;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
        _statusMessage = null;
        _savedFilePath = null;
      });
    }
  }

  Future<void> _encryptFile() async {
    if (_selectedFilePath == null) {
      _showStatus('Pick a file first', false);
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showStatus('Enter a password', false);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Read file bytes
      final fileBytes = await File(_selectedFilePath!).readAsBytes();

      // Encrypt file bytes
      final encrypted = EncryptionService.encryptBytes(
        fileBytes,
        _passwordController.text,
      );

      // Generate hash
      final hash = EncryptionService.generateHash(encrypted);

      // Save encrypted file
      final dir = await getDownloadsDirectory();
      final fileName =
          'encrypted_${DateTime.now().millisecondsSinceEpoch}.cvault';
      final outputFile = File('${dir!.path}/$fileName');
      await outputFile.writeAsBytes(encrypted);

      setState(() {
        _savedFilePath = outputFile.path;
      });

      _showStatus(
        'File encrypted!\nSaved as $fileName\nHash: ${hash.substring(0, 20)}...',
        true,
      );
    } catch (e) {
      _showStatus('Error: ${e.toString()}', false);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _decryptFile() async {
    if (_selectedFilePath == null) {
      _showStatus('Pick an encrypted .cvault file first', false);
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showStatus('Enter the password', false);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final fileBytes = await File(_selectedFilePath!).readAsBytes();

      final decrypted = EncryptionService.decryptBytes(
        fileBytes,
        _passwordController.text,
      );

      final dir = await getDownloadsDirectory();
      final fileName = 'decrypted_${DateTime.now().millisecondsSinceEpoch}.bin';
      final outputFile = File('${dir!.path}/$fileName');
      await outputFile.writeAsBytes(decrypted);

      _showStatus('File decrypted!\nSaved as $fileName', true);
    } catch (e) {
      _showStatus('Wrong password or invalid file', false);
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
          'File Encrypt / Decrypt',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File picker
            _label('Select File'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedFileName != null
                        ? const Color(0xFFFF6B6B)
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      color: _selectedFileName != null
                          ? const Color(0xFFFF6B6B)
                          : Colors.white24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedFileName ?? 'Tap to pick any file',
                        style: TextStyle(
                          color: _selectedFileName != null
                              ? Colors.white
                              : Colors.white24,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Password
            _label('Password'),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Enter password...'),
            ),
            const SizedBox(height: 28),

            // Encrypt button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _encryptFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Encrypt File',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Decrypt button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _isProcessing ? null : _decryptFile,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF6B6B)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Decrypt .cvault File',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status
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
      borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
    ),
  );
}
