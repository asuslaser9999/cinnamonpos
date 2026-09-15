import 'package:flutter/material.dart';

import '../models/app_appearance.dart';
import '../theme/app_theme.dart';

class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({
    super.key,
    required this.appearance,
    required this.selected,
    required this.onTap,
  });

  final AppAppearance appearance;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = switch (appearance) {
      AppAppearance.dark => (
          canvas: AppColors.background,
          card: AppColors.surfaceLight,
          ink: AppColors.textPrimary,
          muted: AppColors.textMuted,
          accent: AppColors.accentBlue,
          icon: Icons.dark_mode_rounded,
        ),
      AppAppearance.bright => (
          canvas: AppleBrightColors.canvas,
          card: AppleBrightColors.white,
          ink: AppleBrightColors.ink,
          muted: AppleBrightColors.muted,
          accent: AppleBrightColors.blue,
          icon: Icons.wb_sunny_rounded,
        ),
      AppAppearance.pos => (
          canvas: PosColors.navy,
          card: PosColors.charcoal,
          ink: PosColors.ink,
          muted: PosColors.muted,
          accent: PosColors.terracotta,
          icon: Icons.point_of_sale_rounded,
        ),
    };
    final canvas = preview.canvas;
    final card = preview.card;
    final ink = preview.ink;
    final muted = preview.muted;
    final accent = preview.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 108,
                decoration: BoxDecoration(
                  color: canvas,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          preview.icon,
                          size: 16,
                          color: accent,
                        ),
                        const Spacer(),
                        Container(
                          width: 28,
                          height: 10,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(10),
                        border: appearance == AppAppearance.pos
                            ? Border.all(color: PosColors.line)
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.centerLeft,
                      child: appearance == AppAppearance.pos
                          ? Row(
                              children: [
                                _PreviewDot(color: PosColors.navy),
                                const SizedBox(width: 4),
                                _PreviewDot(color: PosColors.charcoal),
                                const SizedBox(width: 4),
                                _PreviewDot(color: PosColors.terracotta),
                                const SizedBox(width: 4),
                                _PreviewDot(color: PosColors.sage),
                                const SizedBox(width: 4),
                                _PreviewDot(color: PosColors.camel),
                                const Spacer(),
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: PosColors.terracotta,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: ink.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 32,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: muted.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                child: Text(
                  appearance.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewDot extends StatelessWidget {
  const _PreviewDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

