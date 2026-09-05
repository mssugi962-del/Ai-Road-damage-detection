import 'dart:async';

import 'package:flutter/material.dart';

class LoadingOverlay extends StatefulWidget {
  final bool visible;
  final Widget child;

  const LoadingOverlay({super.key, required this.visible, required this.child});

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  static const _messages = [
    'Analyzing road surface...',
    'Detecting potholes and cracks...',
    'Calculating severity...',
  ];

  Timer? _timer;
  int _index = 0;

  @override
  void didUpdateWidget(covariant LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _timer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted) {
          setState(() => _index = (_index + 1) % _messages.length);
        }
      });
    } else if (!widget.visible && oldWidget.visible) {
      _timer?.cancel();
      _index = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedOpacity(
          opacity: widget.visible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            ignoring: !widget.visible,
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _ScannerPulse(),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _messages[_index],
                          key: ValueKey(_index),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScannerPulse extends StatelessWidget {
  const _ScannerPulse();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      onEnd: () {},
      child: Container(
        height: 74,
        width: 74,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE7F8F3),
        ),
        child: const Icon(Icons.document_scanner_outlined, size: 34),
      ),
    );
  }
}
