import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import 'gradient_avatar.dart';

class StoreBrandingHeader extends StatelessWidget {
  const StoreBrandingHeader({
    super.key,
    required this.settings,
    this.avatarSize = 88,
    this.iconSize = 40,
    this.nameFontSize = 22,
    this.showSubtitle = false,
    this.center = true,
  });

  final AppSettings settings;
  final double avatarSize;
  final double iconSize;
  final double nameFontSize;
  final bool showSubtitle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final subtitle = settings.storeSubtitle.trim();
    final scheme = Theme.of(context).colorScheme;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        GradientAvatar(
          size: avatarSize,
          color: settings.avatarColor,
          child: Icon(settings.storeIcon, size: iconSize, color: Colors.white),
        ),
        SizedBox(height: avatarSize >= 96 ? 24 : 16),
        Text(
          settings.storeName.trim().isEmpty
              ? AppSettings.defaults.storeName
              : settings.storeName.trim(),
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: nameFontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        if (showSubtitle && subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: nameFontSize >= 24 ? 16 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );

    if (center) {
      return Center(child: content);
    }
    return content;
  }
}
