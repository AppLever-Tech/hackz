import 'package:flutter/material.dart';

class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.formContent,
    required this.nextLabel,
    required this.onNext,
    required this.onCancel,
    this.isLoading = false,
    this.extraContent,
    this.titleFontSize = 40,
    this.actionsInRow = true,
  });

  final String title;
  final String? subtitle;
  final Widget formContent;
  final String nextLabel;
  final VoidCallback? onNext;
  final VoidCallback onCancel;
  final bool isLoading;
  final Widget? extraContent;
  final double titleFontSize;
  final bool actionsInRow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFEDEBFF),
              Color(0xFFF7ECFF),
              Color(0xFFF9F1FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xB3FFFFFF),
                      width: 1.2,
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 4),
                      Image.asset(
                        'assets/images/hackz_logo.png',
                        height: 170,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10143B),
                        ),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF43486A),
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      formContent,
                      if (extraContent != null) ...<Widget>[
                        const SizedBox(height: 16),
                        extraContent!,
                      ],
                      const SizedBox(height: 20),
                      if (actionsInRow)
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _nextButton(),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _cancelButton(),
                            ),
                          ],
                        )
                      else ...<Widget>[
                        SizedBox(
                          width: double.infinity,
                          child: _nextButton(),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: _cancelButton(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nextButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF6A38FF), Color(0xFFFF8C2B)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: FilledButton(
        onPressed: isLoading ? null : onNext,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(nextLabel),
      ),
    );
  }

  Widget _cancelButton() {
    return OutlinedButton(
      onPressed: onCancel,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: const BorderSide(color: Color(0xFFA5ABD0)),
        foregroundColor: const Color(0xFF202658),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text('Cancel'),
    );
  }
}
