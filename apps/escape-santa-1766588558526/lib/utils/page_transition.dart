import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  FadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 600),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Black overlay opacity: fades in from 0 to 1 in first half, then fades out from 1 to 0 in second half
            final blackOverlayOpacity = animation.value < 0.5
                ? animation.value * 2 // 0.0 -> 1.0 in first half
                : (1.0 - animation.value) * 2; // 1.0 -> 0.0 in second half

            // New page opacity: invisible in first half, fades in during second half
            final pageOpacity = animation.value < 0.5
                ? 0.0
                : (animation.value - 0.5) * 2;

            return Stack(
              children: [
                // The new page fading in
                Opacity(
                  opacity: pageOpacity,
                  child: child,
                ),
                // Black overlay
                IgnorePointer(
                  child: Opacity(
                    opacity: blackOverlayOpacity,
                    child: Container(
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            );
          },
        );
}
