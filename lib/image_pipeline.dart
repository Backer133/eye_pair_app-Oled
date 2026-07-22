// PNG -> 466x466 RGB565 Konvertierung fuer Cloud-Eye-Upload via BLE.
// Zielgeraet: ESP32-S3-Touch-AMOLED-1.43 (CO5300, 466x466). LVGL erwartet little-endian
// RGB565: low-byte zuerst.

import 'dart:typed_data';
import 'package:image/image.dart' as img;

const int kEyeWidth  = 466;
const int kEyeHeight = 466;
const int kRgb565ByteCount = kEyeWidth * kEyeHeight * 2;  // 434312 Bytes

/// Decodiert PNG/JPG, resized auf 466x466, konvertiert zu RGB565 LE.
/// Bild wird unveraendert uebertragen - keine Hintergrund-Konvertierung.
/// Tipp: PNG bitte direkt mit weissem Hintergrund hochladen (Display ist weiss).
Uint8List pngToRgb565(Uint8List pngBytes) {
  final src = img.decodeImage(pngBytes);
  if (src == null) {
    throw Exception('PNG/JPG konnte nicht dekodiert werden');
  }
  final resized = (src.width != kEyeWidth || src.height != kEyeHeight)
      ? img.copyResize(src, width: kEyeWidth, height: kEyeHeight, interpolation: img.Interpolation.linear)
      : src;

  final out = Uint8List(kRgb565ByteCount);
  int o = 0;
  for (int y = 0; y < kEyeHeight; y++) {
    for (int x = 0; x < kEyeWidth; x++) {
      final p = resized.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();

      final r5 = (r >> 3) & 0x1F;
      final g6 = (g >> 2) & 0x3F;
      final b5 = (b >> 3) & 0x1F;
      final v = (r5 << 11) | (g6 << 5) | b5;
      // little-endian
      out[o++] = v & 0xFF;
      out[o++] = (v >> 8) & 0xFF;
    }
  }
  return out;
}
