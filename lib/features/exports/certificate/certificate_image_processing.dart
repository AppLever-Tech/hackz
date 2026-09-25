import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Raster prep for certificate PDF embeds (college logos, signatory scans, etc.).
abstract final class CertificateImageProcessing {
  CertificateImageProcessing._();

  /// Certificate page fill ([CertificateTheme.ivory]).
  static const int paperR = 0xFC;
  static const int paperG = 0xF8;
  static const int paperB = 0xF0;

  /// Keys scan/upload paper from the edges so artwork blends with certificate ivory.
  static Uint8List prepareCertificateEmbed(Uint8List bytes) {
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    final _Rgb bg = _estimatePaperBackground(decoded);
    final List<List<bool>> isPaper = List<List<bool>>.generate(
      decoded.height,
      (int y) => List<bool>.generate(
        decoded.width,
        (int x) {
          final img.Pixel p = decoded.getPixel(x, y);
          if (p.a.toInt() < 16) return true;
          return _isPaperPixel(
            p.r.toInt(),
            p.g.toInt(),
            p.b.toInt(),
            bg,
          );
        },
      ),
    );

    final List<List<bool>> flooded = _floodPaperFromEdges(isPaper);
    final img.Image out = img.Image(width: decoded.width, height: decoded.height, numChannels: 4);
    for (int y = 0; y < decoded.height; y++) {
      for (int x = 0; x < decoded.width; x++) {
        final img.Pixel p = decoded.getPixel(x, y);
        final int r = p.r.toInt();
        final int g = p.g.toInt();
        final int b = p.b.toInt();
        final int alpha = flooded[y][x] ? 0 : 255;
        out.setPixelRgba(x, y, r, g, b, alpha);
      }
    }

    _peelLightHalos(out);
    return Uint8List.fromList(img.encodePng(out));
  }

  static List<List<bool>> _floodPaperFromEdges(List<List<bool>> isPaper) {
    final int h = isPaper.length;
    final int w = isPaper.first.length;
    final List<List<bool>> flooded = List<List<bool>>.generate(
      h,
      (_) => List<bool>.filled(w, false),
    );
    final Queue<(int x, int y)> queue = Queue<(int x, int y)>();

    void seed(int x, int y) {
      if (x < 0 || y < 0 || x >= w || y >= h) return;
      if (!isPaper[y][x] || flooded[y][x]) return;
      flooded[y][x] = true;
      queue.add((x, y));
    }

    for (int x = 0; x < w; x++) {
      seed(x, 0);
      seed(x, h - 1);
    }
    for (int y = 0; y < h; y++) {
      seed(0, y);
      seed(w - 1, y);
    }

    while (queue.isNotEmpty) {
      final (int x, int y) = queue.removeFirst();
      seed(x + 1, y);
      seed(x - 1, y);
      seed(x, y + 1);
      seed(x, y - 1);
    }
    return flooded;
  }

  static void _peelLightHalos(img.Image out) {
    final int w = out.width;
    final int h = out.height;
    bool changed = true;
    int pass = 0;
    while (changed && pass < 4) {
      changed = false;
      pass++;
      final List<List<bool>> remove = List<List<bool>>.generate(
        h,
        (_) => List<bool>.filled(w, false),
      );
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          if (out.getPixel(x, y).a.toInt() == 0) continue;
          final int r = out.getPixel(x, y).r.toInt();
          final int g = out.getPixel(x, y).g.toInt();
          final int b = out.getPixel(x, y).b.toInt();
          if (!_isHaloPixel(r, g, b)) continue;
          if (_touchesTransparent(out, x, y)) {
            remove[y][x] = true;
          }
        }
      }
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          if (remove[y][x]) {
            out.setPixelRgba(x, y, 0, 0, 0, 0);
            changed = true;
          }
        }
      }
    }
  }

  static bool _touchesTransparent(img.Image out, int x, int y) {
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final int nx = x + dx;
        final int ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= out.width || ny >= out.height) continue;
        if (out.getPixel(nx, ny).a.toInt() < 16) return true;
      }
    }
    return false;
  }

  static bool _isHaloPixel(int r, int g, int b) {
    final int maxChannel = math.max(r, math.max(g, b));
    final int minChannel = math.min(r, math.min(g, b));
    if (maxChannel - minChannel > 22) return false;
    if (maxChannel < 195) return false;
    if (_distance(r, g, b, paperR, paperG, paperB) <= 40) return true;
    return maxChannel > 230 && minChannel > 200;
  }

  static bool _isPaperPixel(int r, int g, int b, _Rgb bg) {
    final int maxChannel = math.max(r, math.max(g, b));
    final int minChannel = math.min(r, math.min(g, b));
    if (maxChannel < 28) return true;
    if (minChannel > 246) return true;
    if (_distance(r, g, b, paperR, paperG, paperB) <= 38) return true;
    if (_distance(r, g, b, bg.r, bg.g, bg.b) <= 42) return true;
    if (maxChannel - minChannel < 16 && maxChannel > 200) return true;
    return false;
  }

  static _Rgb _estimatePaperBackground(img.Image source) {
    final List<_Rgb> samples = <_Rgb>[];
    void sample(int x, int y) {
      if (x < 0 || y < 0 || x >= source.width || y >= source.height) return;
      final img.Pixel p = source.getPixel(x, y);
      samples.add(_Rgb(p.r.toInt(), p.g.toInt(), p.b.toInt()));
    }

    final int w = source.width;
    final int h = source.height;
    for (int i = 0; i < 8; i++) {
      final int t = (w > 1) ? (i * (w - 1) ~/ 7) : 0;
      sample(t, 0);
      sample(t, h - 1);
    }
    for (int i = 1; i < 7; i++) {
      final int t = (h > 1) ? (i * (h - 1) ~/ 6) : 0;
      sample(0, t);
      sample(w - 1, t);
    }

    if (samples.isEmpty) {
      return const _Rgb(paperR, paperG, paperB);
    }
    final int avgR = samples.map((_Rgb s) => s.r).reduce((int a, int b) => a + b) ~/ samples.length;
    final int avgG = samples.map((_Rgb s) => s.g).reduce((int a, int b) => a + b) ~/ samples.length;
    final int avgB = samples.map((_Rgb s) => s.b).reduce((int a, int b) => a + b) ~/ samples.length;
    return _Rgb(avgR, avgG, avgB);
  }

  static double _distance(int r1, int g1, int b1, int r2, int g2, int b2) {
    final double dr = (r1 - r2).toDouble();
    final double dg = (g1 - g2).toDouble();
    final double db = (b1 - b2).toDouble();
    return math.sqrt(dr * dr + dg * dg + db * db);
  }
}

class _Rgb {
  const _Rgb(this.r, this.g, this.b);
  final int r;
  final int g;
  final int b;
}
