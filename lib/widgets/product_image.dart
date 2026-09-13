import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    this.imageUrl,
    this.bytes,
    this.size,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final Uint8List? bytes;
  final double? size;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  bool get _hasImage =>
      bytes != null || (imageUrl != null && imageUrl!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppShapes.borderSmall;
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.bakery_dining_rounded,
          color: context.palette.textMuted,
          size: size == null ? 36 : size! * 0.42,
        ),
      ),
    );

    final image = !_hasImage
        ? placeholder
        : bytes != null
        ? Image.memory(bytes!, fit: fit, width: size, height: size)
        : Image.network(
            imageUrl!,
            fit: fit,
            width: size,
            height: size,
            errorBuilder: (_, _, _) => placeholder,
          );

    return ClipRRect(
      borderRadius: radius,
      child: size == null
          ? SizedBox.expand(child: image)
          : SizedBox(width: size, height: size, child: image),
    );
  }
}
