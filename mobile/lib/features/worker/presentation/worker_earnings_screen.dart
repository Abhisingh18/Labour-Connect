import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/states.dart';
import '../../shared/models/worker_model.dart';
import 'worker_providers.dart';

class WorkerEarningsScreen extends ConsumerWidget {
  const WorkerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(workerEarningsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        automaticallyImplyLeading: false,
      ),
      body: earnings.when(
        loading: () => const ListSkeleton(itemHeight: 120),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(workerEarningsProvider),
        ),
        data: (e) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(workerEarningsProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total earnings',
                        style: AppText.label.copyWith(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text(
                      Formatters.money(e.totalEarnings),
                      style: AppText.display.copyWith(color: Colors.white, fontSize: 34),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.task_alt_rounded, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text('${e.completedJobs} completed jobs',
                            style: AppText.label.copyWith(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (e.monthly.isNotEmpty) ...[
                Text('Monthly trend', style: AppText.h2),
                const SizedBox(height: 16),
                _EarningsChart(monthly: e.monthly),
                const SizedBox(height: 24),
                Text('Breakdown', style: AppText.h2),
                const SizedBox(height: 12),
                ...e.monthly.reversed.map((m) => _MonthRow(item: m)),
              ] else
                const EmptyState(
                  icon: Icons.bar_chart_rounded,
                  title: 'No earnings yet',
                  message: 'Complete jobs to start earning. Your history will show here.',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EarningsChart extends StatelessWidget {
  final List<MonthlyEarning> monthly;
  const _EarningsChart({required this.monthly});

  @override
  Widget build(BuildContext context) {
    final data = monthly.length > 6
        ? monthly.sublist(monthly.length - 6)
        : monthly;
    final maxY = data.map((e) => e.amount).fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 100 : maxY * 1.25,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY == 0 ? 50 : maxY / 2,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.divider, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  final label = Formatters.monthLabel(data[i].month).split(' ').first;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(label, style: AppText.caption),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].amount,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                    gradient: AppColors.primaryGradient,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  final MonthlyEarning item;
  const _MonthRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Text(Formatters.monthLabel(item.month), style: AppText.title),
          const Spacer(),
          Text(Formatters.money(item.amount),
              style: AppText.h3.copyWith(color: AppColors.success)),
        ],
      ),
    );
  }
}
