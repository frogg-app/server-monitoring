import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/metrics.dart';
import '../providers/metrics_provider.dart';

/// Line chart widget for displaying metric history
class MetricChart extends StatelessWidget {
  final MetricSeries series;
  final Color? color;
  final bool showLabels;
  final double height;

  const MetricChart({
    super.key,
    required this.series,
    this.color,
    this.showLabels = true,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chartColor = color ?? theme.colorScheme.primary;

    if (series.points.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No data available')),
      );
    }

    final spots = series.points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final minY = series.min * 0.9;
    final maxY = series.max * 1.1;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.outline.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: showLabels,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLabels,
                reservedSize: 30,
                interval: series.points.length / 4,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= series.points.length) {
                    return const SizedBox.shrink();
                  }
                  final time = series.points[index].timestamp;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLabels,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatValue(value),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (series.points.length - 1).toDouble(),
          minY: minY.clamp(0, double.infinity),
          maxY: maxY.clamp(minY + 1, double.infinity),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: chartColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    chartColor.withOpacity(0.3),
                    chartColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: theme.colorScheme.surface,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index < 0 || index >= series.points.length) return null;
                  final point = series.points[index];
                  return LineTooltipItem(
                    '${_formatValue(point.value)}\n${_formatTime(point.timestamp)}',
                    theme.textTheme.bodySmall!,
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else if (value >= 100) {
      return value.toStringAsFixed(0);
    } else {
      return value.toStringAsFixed(1);
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}

/// Gauge chart for current value display
class MetricGauge extends StatelessWidget {
  final double value;
  final double maxValue;
  final String label;
  final String valueLabel;
  final Color? color;

  const MetricGauge({
    super.key,
    required this.value,
    this.maxValue = 100,
    required this.label,
    required this.valueLabel,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (value / maxValue).clamp(0.0, 1.0);
    final gaugeColor = color ?? _getColorForPercentage(percentage);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 8,
                  backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(gaugeColor),
                ),
              ),
              Text(
                valueLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 0.9) return Colors.red;
    if (percentage >= 0.7) return Colors.orange;
    if (percentage >= 0.5) return Colors.yellow.shade700;
    return Colors.green;
  }
}

/// Time range selector chip group
class TimeRangeSelector extends ConsumerWidget {
  const TimeRangeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRange = ref.watch(selectedTimeRangeProvider);

    return Wrap(
      spacing: 8,
      children: TimeRange.values.map((range) {
        final isSelected = range == selectedRange;
        return ChoiceChip(
          label: Text(range.label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              ref.read(selectedTimeRangeProvider.notifier).state = range;
            }
          },
        );
      }).toList(),
    );
  }
}

/// Current metrics card displaying gauges
class CurrentMetricsCard extends ConsumerWidget {
  final String serverId;

  const CurrentMetricsCard({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsState = ref.watch(currentMetricsProvider(serverId));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Metrics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () {
                    ref.read(currentMetricsProvider(serverId).notifier).refresh();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            switch (metricsState) {
              CurrentMetricsLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
              CurrentMetricsError(message: final msg) => Center(
                  child: Text('Error: $msg'),
                ),
              CurrentMetricsLoaded(metrics: final m) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    MetricGauge(
                      value: m.cpuPercent,
                      label: 'CPU',
                      valueLabel: '${m.cpuPercent.toStringAsFixed(1)}%',
                    ),
                    MetricGauge(
                      value: m.memoryPercent,
                      label: 'Memory',
                      valueLabel: '${m.memoryPercent.toStringAsFixed(1)}%',
                    ),
                    MetricGauge(
                      value: m.diskPercent,
                      label: 'Disk',
                      valueLabel: '${m.diskPercent.toStringAsFixed(1)}%',
                    ),
                    Column(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.uptimeFormatted,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Uptime',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            },
          ],
        ),
      ),
    );
  }
}
