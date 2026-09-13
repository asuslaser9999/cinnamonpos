import 'dart:io';

import 'package:flutter/material.dart';

import '../models/app_settings.dart';

class StoreHeroBanner extends StatelessWidget {
  const StoreHeroBanner({
    super.key,
    required this.settings,
    this.height = 180,
  });

  final AppSettings settings;
  final double height;

  @override
  Widget build(BuildContext context) {
    final path = settings.heroBannerPath?.trim();
    if (path == null || path.isEmpty) {
      return const SizedBox.shrink();
    }

    final file = File(path);
    if (!file.existsSync()) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Image.file(
        file,
        key: ValueKey(settings.heroBannerVersion),
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
