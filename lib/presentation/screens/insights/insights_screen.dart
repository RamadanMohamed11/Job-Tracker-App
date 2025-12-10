import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/status_options.dart';
import '../../../data/models/job_application.dart';
import '../../cubits/jobs_cubit.dart';

// ============================================
// INSIGHTS SCREEN
// ============================================
// Displays analytics and charts for job applications:
// - Jobs by source (pie chart)
// - Success rate by source (bar chart)
// - Jobs applied per month (bar chart with time period selection)

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  // Time period selection for monthly chart
  int _selectedMonths = 6; // Default: last 6 months

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Insights')),
      body: BlocBuilder<JobsCubit, JobsState>(
        builder: (context, state) {
          if (state.jobs.isEmpty) {
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                _buildSummaryCards(state.jobs),
                const SizedBox(height: 24),

                // Jobs by Source - Pie Chart
                _buildSectionHeader('Jobs by Source'),
                const SizedBox(height: 12),
                _buildJobsBySourceChart(state.jobs),
                const SizedBox(height: 24),

                // Success Rate by Source - Bar Chart
                _buildSectionHeader('Success Rate by Source'),
                const SizedBox(height: 12),
                _buildSuccessRateChart(state.jobs),
                const SizedBox(height: 24),

                // Jobs Per Month - Bar Chart with Period Selection
                _buildSectionHeader('Applications Over Time'),
                const SizedBox(height: 8),
                _buildPeriodSelector(),
                const SizedBox(height: 12),
                _buildJobsPerMonthChart(state.jobs),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding job applications to see insights',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<JobApplication> jobs) {
    final successCount = jobs
        .where(
          (j) =>
              j.statusEnum == JobStatus.offerReceived ||
              j.statusEnum == JobStatus.accepted,
        )
        .length;
    final interviewCount = jobs
        .where(
          (j) =>
              j.statusEnum == JobStatus.interviewScheduled ||
              j.statusEnum == JobStatus.interviewed,
        )
        .length;
    // Note: rejectedCount could be used for future analytics
    final successRate = jobs.isNotEmpty
        ? (successCount / jobs.length * 100).toStringAsFixed(1)
        : '0';

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total',
            value: '${jobs.length}',
            icon: Icons.work_outline,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Interviews',
            value: '$interviewCount',
            icon: Icons.event,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Success',
            value: '$successRate%',
            icon: Icons.trending_up,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildJobsBySourceChart(List<JobApplication> jobs) {
    final sourceMap = <String, int>{};
    for (final job in jobs) {
      final source = job.source ?? 'Unknown';
      sourceMap[source] = (sourceMap[source] ?? 0) + 1;
    }

    if (sourceMap.isEmpty) {
      return _buildNoDataWidget();
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    final sections = <PieChartSectionData>[];
    int colorIndex = 0;
    sourceMap.forEach((source, count) {
      final percentage = (count / jobs.length * 100);
      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          title: '${percentage.toStringAsFixed(0)}%',
          color: colors[colorIndex % colors.length],
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(sourceMap, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Map<String, int> data, List<Color> colors) {
    int colorIndex = 0;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: data.entries.map((entry) {
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              '${entry.key} (${entry.value})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSuccessRateChart(List<JobApplication> jobs) {
    final sourceStats = <String, Map<String, int>>{};

    for (final job in jobs) {
      final source = job.source ?? 'Unknown';
      sourceStats[source] ??= {'total': 0, 'success': 0};
      sourceStats[source]!['total'] = (sourceStats[source]!['total'] ?? 0) + 1;

      if (job.statusEnum == JobStatus.offerReceived ||
          job.statusEnum == JobStatus.accepted) {
        sourceStats[source]!['success'] =
            (sourceStats[source]!['success'] ?? 0) + 1;
      }
    }

    if (sourceStats.isEmpty) {
      return _buildNoDataWidget();
    }

    final sortedSources = sourceStats.keys.toList()
      ..sort(
        (a, b) =>
            sourceStats[b]!['total']!.compareTo(sourceStats[a]!['total']!),
      );

    // Take top 6 sources
    final displaySources = sortedSources.take(6).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              barGroups: displaySources.asMap().entries.map((entry) {
                final source = entry.value;
                final stats = sourceStats[source]!;
                final successRate = stats['total']! > 0
                    ? (stats['success']! / stats['total']! * 100)
                    : 0.0;

                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: successRate,
                      color: successRate > 20 ? Colors.green : Colors.grey,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < displaySources.length) {
                        final source = displaySources[index];
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            source.length > 8
                                ? '${source.substring(0, 8)}...'
                                : source,
                            style: const TextStyle(fontSize: 9),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _PeriodChip(
          label: '3 Months',
          isSelected: _selectedMonths == 3,
          onTap: () => setState(() => _selectedMonths = 3),
        ),
        const SizedBox(width: 8),
        _PeriodChip(
          label: '6 Months',
          isSelected: _selectedMonths == 6,
          onTap: () => setState(() => _selectedMonths = 6),
        ),
        const SizedBox(width: 8),
        _PeriodChip(
          label: '12 Months',
          isSelected: _selectedMonths == 12,
          onTap: () => setState(() => _selectedMonths = 12),
        ),
        const SizedBox(width: 8),
        _PeriodChip(
          label: 'All Time',
          isSelected: _selectedMonths == 0,
          onTap: () => setState(() => _selectedMonths = 0),
        ),
      ],
    );
  }

  Widget _buildJobsPerMonthChart(List<JobApplication> jobs) {
    final now = DateTime.now();
    final monthlyData = <String, int>{};

    // Initialize months
    final monthsToShow = _selectedMonths == 0 ? 24 : _selectedMonths;
    for (int i = monthsToShow - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM yy').format(month);
      monthlyData[key] = 0;
    }

    // Count jobs per month
    for (final job in jobs) {
      String? dateStr = job.applicationDate ?? job.createdAt;
      try {
        final date = DateTime.parse(dateStr);
        final key = DateFormat('MMM yy').format(date);
        if (monthlyData.containsKey(key)) {
          monthlyData[key] = (monthlyData[key] ?? 0) + 1;
        }
      } catch (_) {}
    }

    if (monthlyData.isEmpty) {
      return _buildNoDataWidget();
    }

    final maxY =
        (monthlyData.values.isEmpty
                ? 10
                : monthlyData.values.reduce((a, b) => a > b ? a : b))
            .toDouble() +
        2;

    final entries = monthlyData.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barGroups: entries.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value.toDouble(),
                      color: Theme.of(context).colorScheme.primary,
                      width: _selectedMonths == 0 ? 8 : 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: maxY > 10 ? (maxY / 5).ceilToDouble() : 1,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      // Show every nth label based on period
                      final step = _selectedMonths == 0
                          ? 3
                          : (_selectedMonths > 6 ? 2 : 1);
                      if (index >= 0 &&
                          index < entries.length &&
                          index % step == 0) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          angle: 45 * (3.14159 / 180),
                          child: Text(
                            entries[index].key,
                            style: const TextStyle(fontSize: 9),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// HELPER WIDGETS
// ============================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
