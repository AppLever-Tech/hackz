import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  for (final String path in <String>[
    'assets/branding/hackz_primary_logo.png',
    'assets/branding/hackz_launcher_logo.png',
    'assets/branding/hackz_symbol.png',
    'assets/branding/hackz_loading_symbol.png',
  ]) {
    check(path);
  }
}

void check(String path) {
  final bytes = File(path).readAsBytesSync();
  final im = img.decodeImage(bytes);
  if (im == null) {
    print('$path: decode failed');
    return;
  }
  print('$path: ${im.width}x${im.height} channels=${im.numChannels}');
  int transparent = 0, black = 0, white = 0, other = 0;
  for (int y = 0; y < im.height; y++) {
    for (int x = 0; x < im.width; x++) {
      final p = im.getPixel(x, y);
      final a = p.a.toInt();
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      if (a < 16) {
        transparent++;
      } else if (r < 28 && g < 28 && b < 28) {
        black++;
      } else if (r > 242 && g > 242 && b > 242) {
        white++;
      } else {
        other++;
      }
    }
  }
  print('  transparent=$transparent opaqueBlack=$black opaqueWhite=$white colored=$other');
  final c = im.getPixel(0, 0);
  print('  corner(0,0): r=${c.r} g=${c.g} b=${c.b} a=${c.a}');
}
