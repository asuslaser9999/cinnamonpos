import 'package:flutter/material.dart';

/// M3-inspired dark backdrop with subtle tonal wash.
class DarkBackground extends StatelessWidget {
  const DarkBackground({super.key, required this.child, this.showOrbs = true});

  final Widget child;
  final bool showOrbs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Stack(
      children: [
        ColoredBox(color: scheme.surface, child: const SizedBox.expand()),
        if (showOrbs && !isLight) ...[
          Positioned(
            top: -100,
            right: -80,
            child: _GradientOrb(
              size: 240,
              color: scheme.primary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: _GradientOrb(
              size: 200,
              color: scheme.secondary.withValues(alpha: 0.06),
            ),
          ),
        ],
        child,
      ],
    );
  }
}

class _GradientOrb extends StatelessWidget {
  const _GradientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
