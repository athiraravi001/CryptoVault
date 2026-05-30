import 'dart:typed_data';
import 'package:image/image.dart' as img;

class SteganographyService {
  static const _delimiter = '<<<END>>>';

  static Uint8List hideTextInImage(Uint8List imageBytes, String text) {
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Invalid image');

    // Convert to PNG-safe format first
    final pngImage = img.Image.from(image);

    final payload = text + _delimiter;
    final payloadBytes = payload.codeUnits;
    final totalBits = payloadBytes.length * 8;
    final capacity = pngImage.width * pngImage.height * 3;

    if (totalBits > capacity) {
      throw Exception('Image too small to hide this data');
    }

    int bitIndex = 0;
    final totalPayloadBits = payloadBytes.length * 8;

    outer:
    for (int y = 0; y < pngImage.height; y++) {
      for (int x = 0; x < pngImage.width; x++) {
        if (bitIndex >= totalPayloadBits) break outer;

        final pixel = pngImage.getPixel(x, y);
        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        final byteIndex = bitIndex ~/ 8;
        final bitPos = 7 - (bitIndex % 8);
        final bit = (payloadBytes[byteIndex] >> bitPos) & 1;
        r = (r & 0xFE) | bit;
        bitIndex++;

        if (bitIndex < totalPayloadBits) {
          final byteIndex2 = bitIndex ~/ 8;
          final bitPos2 = 7 - (bitIndex % 8);
          final bit2 = (payloadBytes[byteIndex2] >> bitPos2) & 1;
          g = (g & 0xFE) | bit2;
          bitIndex++;
        }

        if (bitIndex < totalPayloadBits) {
          final byteIndex3 = bitIndex ~/ 8;
          final bitPos3 = 7 - (bitIndex % 8);
          final bit3 = (payloadBytes[byteIndex3] >> bitPos3) & 1;
          b = (b & 0xFE) | bit3;
          bitIndex++;
        }

        pngImage.setPixelRgb(x, y, r, g, b);
      }
    }

    return Uint8List.fromList(img.encodePng(pngImage));
  }

  static String extractTextFromImage(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Invalid image');

    final bits = <int>[];
    final bytes = <int>[];
    String result = '';

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        bits.add(pixel.r.toInt() & 1);
        bits.add(pixel.g.toInt() & 1);
        bits.add(pixel.b.toInt() & 1);

        while (bits.length >= 8) {
          int byte = 0;
          for (int i = 0; i < 8; i++) {
            byte = (byte << 1) | bits[i];
          }
          bits.removeRange(0, 8);
          bytes.add(byte);

          result = String.fromCharCodes(bytes);
          if (result.contains(_delimiter)) {
            return result.split(_delimiter)[0];
          }
        }
      }
    }

    throw Exception('No hidden data found in image');
  }
}