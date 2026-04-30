import 'dart:async';
import 'package:flutter/material.dart';

class Notify {
  static void showToast(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3), bool error = false}) {
    final entry = OverlayEntry(builder: (ctx) {
      return Positioned(
        top: 36 + MediaQuery.of(ctx).padding.top,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    error ? const Color(0xFF3b2b2b) : const Color(0xFF222222),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3))
                ],
              ),
              child: Center(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      );
    });

    Overlay.of(context).insert(entry);
    Timer(duration, () {
      try {
        entry.remove();
      } catch (_) {}
    });
  }
}
