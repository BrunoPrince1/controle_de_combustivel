import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/fueling.dart';
import '../utils/format.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key, required this.metrics});

  final List<FuelingMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Registre abastecimentos para ver o dashboard.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final withIndicators = metrics.where((m) => m.kmPerLiter != null).toList();
    final totalSpent =
        metrics.fold<double>(0, (sum, m) => sum + m.fueling.total);
    double? avg(double? Function(FuelingMetric) pick) {
      if (withIndicators.isEmpty) return null;
      return withIndicators.map((m) => pick(m)!).reduce((a, b) => a + b) /
          withIndicators.length;
    }

    final avgKmL = avg((m) => m.kmPerLiter);
    final avgCostKm = avg((m) => m.costPerKm);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total gasto',
                value: brl.format(totalSpent),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Média km/L',
                value: avgKmL == null ? '—' : num2.format(avgKmL),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Média R\$/km',
                value: avgCostKm == null ? '—' : brl.format(avgCostKm),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Valor de cada abastecimento',
          child: _BarSeries(
            values: metrics.map((m) => m.fueling.total).toList(),
            labels: metrics
                .map((m) => shortDateFmt.format(m.fueling.dateTime))
                .toList(),
            format: brl.format,
            color: scheme.primary,
          ),
        ),
        _ChartCard(
          title: 'Consumo (km/L)',
          child: withIndicators.isEmpty
              ? const _NeedMore()
              : _LineSeries(
                  values: withIndicators.map((m) => m.kmPerLiter!).toList(),
                  labels: withIndicators
                      .map((m) => shortDateFmt.format(m.fueling.dateTime))
                      .toList(),
                  format: num2.format,
                  color: scheme.tertiary,
                ),
        ),
        _ChartCard(
          title: 'Custo por quilômetro (R\$/km)',
          child: withIndicators.isEmpty
              ? const _NeedMore()
              : _LineSeries(
                  values: withIndicators.map((m) => m.costPerKm!).toList(),
                  labels: withIndicators
                      .map((m) => shortDateFmt.format(m.fueling.dateTime))
                      .toList(),
                  format: brl.format,
                  color: scheme.secondary,
                ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            SizedBox(height: 220, child: child),
          ],
        ),
      ),
    );
  }
}

class _NeedMore extends StatelessWidget {
  const _NeedMore();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'São necessários pelo menos 2 abastecimentos.',
        textAlign: TextAlign.center,
      ),
    );
  }
}

const _axisStyle = TextStyle(fontSize: 10);

FlTitlesData _titles({
  required List<String> labels,
  required String Function(double) format,
  required double step,
}) {
  const hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));
  return FlTitlesData(
    topTitles: hidden,
    rightTitles: hidden,
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 56,
        getTitlesWidget: (value, meta) => Text(
          format(value),
          style: _axisStyle,
          textAlign: TextAlign.right,
        ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        interval: 1,
        getTitlesWidget: (value, meta) {
          final i = value.toInt();
          if (value != i.toDouble() || i < 0 || i >= labels.length) {
            return const SizedBox.shrink();
          }
          if (i % step.toInt() != 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(labels[i], style: _axisStyle),
          );
        },
      ),
    ),
  );
}

double _step(int n) => n <= 6 ? 1 : (n / 6).ceilToDouble();

class _LineSeries extends StatelessWidget {
  const _LineSeries({
    required this.values,
    required this.labels,
    required this.format,
    required this.color,
  });

  final List<double> values;
  final List<String> labels;
  final String Function(double) format;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final pad = (maxV - minV) == 0 ? maxV * 0.1 + 0.1 : (maxV - minV) * 0.2;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(values.length - 1, 1).toDouble(),
        minY: math.max(0, minV - pad),
        maxY: maxV + pad,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titles(
            labels: labels, format: format, step: _step(values.length)),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${labels[s.x.toInt()]}\n${format(s.y)}',
                      const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData:
                BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}

class _BarSeries extends StatelessWidget {
  const _BarSeries({
    required this.values,
    required this.labels,
    required this.format,
    required this.color,
  });

  final List<double> values;
  final List<String> labels;
  final String Function(double) format;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxV = values.reduce(math.max);

    return BarChart(
      BarChartData(
        maxY: maxV * 1.2,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titles(
            labels: labels, format: format, step: _step(values.length)),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
              '${labels[group.x]}\n${format(rod.toY)}',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: color,
                  width: 14,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
