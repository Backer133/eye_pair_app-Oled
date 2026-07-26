// PNG -> 546x546 RGB565 Konvertierung fuer Cloud-Eye-Upload via BLE.
// Zielgeraet: ESP32-C6-Touch-AMOLED-1.43 (CO5300, 546x546). Der esp_lcd_sh8601-Treiber
// schickt die Bytes unveraendert ans Panel und die Firmware nutzt LV_COLOR_16_SWAP=1
// -> RGB565 muss BIG-ENDIAN sein (high-byte zuerst).

import 'dart:typed_data';
import 'package:image/image.dart' as img;

const int kEyeWidth  = 546;   // wie die eingebauten Augen (1:1 gezoomt, formatfuellend)
const int kEyeHeight = 546;
const int kRgb565ByteCount = kEyeWidth * kEyeHeight * 2;  // 596232 Bytes

/// Decodiert PNG/JPG, resized auf 546x546, konvertiert zu RGB565 BE.
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
      // big-endian (high-byte zuerst) -> passend zu LV_COLOR_16_SWAP=1 / esp_lcd_sh8601
      out[o++] = (v >> 8) & 0xFF;
      out[o++] = v & 0xFF;
    }
  }
  return out;
}
