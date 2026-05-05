import 'package:flutter/material.dart';

import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const Size _imageSize = Size(1024, 683);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double screenW = constraints.maxWidth;
            final double screenH = constraints.maxHeight;
            final double scale = (screenW / _imageSize.width) <
                    (screenH / _imageSize.height)
                ? (screenW / _imageSize.width)
                : (screenH / _imageSize.height);
            final double renderedW = _imageSize.width * scale;
            final double renderedH = _imageSize.height * scale;
            final double offsetX = (screenW - renderedW) / 2;
            final double offsetY = (screenH - renderedH) / 2;

            Rect mappedRect(double x, double y, double w, double h) {
              return Rect.fromLTWH(
                offsetX + (x * scale),
                offsetY + (y * scale),
                w * scale,
                h * scale,
              );
            }

            final Rect signInRect = mappedRect(58, 557, 267, 42);
            final Rect signUpRect = mappedRect(58, 609, 267, 42);

            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Center(
                    child: Image.asset(
                      'assets/images/auth_landing.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                _Hotspot(
                  rect: signInRect,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    );
                  },
                ),
                _Hotspot(
                  rect: signUpRect,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Hotspot extends StatelessWidget {
  const _Hotspot({
    required this.rect,
    required this.onTap,
  });

  final Rect rect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
        ),
      ),
    );
  }
}
