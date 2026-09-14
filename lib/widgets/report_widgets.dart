import 'package:flutter/material.dart';

import '../models/pos_reports.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'dark_background.dart';

class ReportPeriodPicker {
  ReportPeriodPicker._();

  static Future<({DateTime start, DateTime end})?> pick(
    BuildContext context, {
    required DateTime start,
    required DateTime end,
  }) async {
    final nextStart = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Dari tanggal',
    );
    if (nextStart == null || !context.mounted) return null;
    final nextEnd = await showDatePicker(
      context: context,
      initialDate: end.isBefore(nextStart) ? nextStart : end,
      firstDate: nextStart,
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Sampai tanggal',
    );
    if (nextEnd == null) return null;
    return (start: nextStart, end: nextEnd);
  }
}

class ReportScaffold extends StatelessWidget {
  const ReportScaffold({
    super.key,
    required this.title,
    required this.periodLabel,
    required this.onPickPeriod,
    required this.isLoading,
    required this.child,
    this.errorMessage,
    this.onRefresh,
  });

  final String title;
  final String periodLabel;
  final VoidCallback onPickPeriod;
  final bool isLoading;
  final Widget? child;
  final String? errorMessage;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (child == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(errorMessage ?? 'Tidak ada data.'),
        ),
      );
    } else {
      body = child!;
    }

    if (onRefresh != null && !isLoading) {
      body = RefreshIndicator(onRefresh: onRefresh!, child: body);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: onPickPeriod,
              icon: const Icon(Icons.date_range_outlined, size: 18),
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  periodLabel,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      body: DarkBackground(child: body),
    );
  }
}

class ReportBody extends StatelessWidget {
  const ReportBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class ReportSection extends StatelessWidget {
  const ReportSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class ReportHeroCard extends StatelessWidget {
  const ReportHeroCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon = Icons.payments_rounded,
    this.color,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: AppShapes.borderMedium,
        color: scheme.surfaceContainer,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: AppShapes.borderSmall,
              color: accent.withValues(alpha: 0.18),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReportMetric {
  const ReportMetric({
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
}

class ReportMetricGrid extends StatelessWidget {
  const ReportMetricGrid({super.key, required this.metrics});

  final List<ReportMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth >= 640;
        if (!twoCol) {
          return Column(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                ReportMetricCard(metric: metrics[i]),
              ],
            ],
          );
        }
        final rows = <Widget>[];
        for (var i = 0; i < metrics.length; i += 2) {
          final left = metrics[i];
          final right = i + 1 < metrics.length ? metrics[i + 1] : null;
          rows.add(
            Padding(
              padding: EdgeInsets.only(bottom: i + 2 < metrics.length ? 8 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: ReportMetricCard(metric: left)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: right == null
                        ? const SizedBox.shrink()
                        : ReportMetricCard(metric: right),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}

class ReportMetricCard extends StatelessWidget {
  const ReportMetricCard({super.key, required this.metric});

  final ReportMetric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = metric.color ?? scheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            if (metric.icon != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: AppShapes.borderSmall,
                  color: accent.withValues(alpha: 0.16),
                ),
                child: Icon(metric.icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metric.value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (metric.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      metric.subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportDonationRecap extends StatelessWidget {
  const ReportDonationRecap({
    super.key,
    required this.total,
    required this.count,
    required this.donations,
  });

  final double total;
  final int count;
  final List<DonationRow> donations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final accent = palette.accentPink;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppShapes.borderMedium,
        color: scheme.surfaceContainer,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: AppShapes.borderSmall,
                    color: accent.withValues(alpha: 0.18),
                  ),
                  child: Icon(
                    Icons.volunteer_activism_outlined,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rekap donasi pembulatan',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Uang ini sudah masuk laci tunai. '
                        'Keluarkan sejumlah total di bawah saat setor donasi.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _DonationStat(
                    label: 'Total donasi',
                    value: CurrencyFormatter.format(total),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DonationStat(
                    label: 'Transaksi donasi',
                    value: '$count',
                  ),
                ),
              ],
            ),
          ),
          if (donations.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Belum ada pelanggan yang memilih donasi di periode ini.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                title: Text(
                  'Rincian ${donations.length} transaksi',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                children: [
                  for (final row in donations)
                    ListTile(
                      dense: true,
                      title: Text(row.saleNumber),
                      subtitle: Text(
                        CurrencyFormatter.formatDateTime(row.soldAt.toLocal()),
                      ),
                      trailing: Text(
                        CurrencyFormatter.format(row.amount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ReportProductTile extends StatelessWidget {
  const ReportProductTile({
    super.key,
    required this.name,
    required this.detail,
    required this.amount,
  });

  final String name;
  final String detail;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(detail),
        trailing: Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _DonationStat extends StatelessWidget {
  const _DonationStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

