import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GradientAvatar extends StatelessWidget {
  const GradientAvatar({
    super.key,
    required this.child,
    this.size = 88,
    this.color = AppColors.accentOrange,
  });

  final Widget child;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(child: child),
    );
  }
}
