// lib/views/vendedor_chart_widget.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/lead.dart';

class VendedorChart extends StatefulWidget {
  final List<Lead> leads;
  const VendedorChart({super.key, required this.leads});

  @override
  State<VendedorChart> createState() => _VendedorChartState();
}

class _VendedorChartState extends State<VendedorChart> {
  static const _green = Color(0xFF22C55E);
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFEF4444);
  static const _blue = Color(0xFF3B82F6);
  static const _bgCard = Color(0xFFFFFFFF);
  static const _divider = Color(0xFFE2E8F0);
  static const _textGrey = Color(0xFF94A3B8);
  static const _textDark = Color(0xFF0F172A);

  bool _showOpen = true, _showDone = true, _showLost = true;

  static const _dayLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  DateTime get _startOfWeek {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  /// Para cada día de la semana (0=Lun … 6=Dom), cuenta leads por estado
  List<Map<String, int>> _getWeeklyData() {
    final monday = _startOfWeek;
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      final leadsDelDia = widget.leads.where((l) {
        final f = l.fechaCreacion;
        return f != null &&
            f.year == day.year &&
            f.month == day.month &&
            f.day == day.day;
      });
      return {
        'open': leadsDelDia
            .where((l) => l.estado.toLowerCase() == 'abierto')
            .length,
        'done': leadsDelDia
            .where((l) => l.estado.toLowerCase() == 'completado')
            .length,
        'lost': leadsDelDia
            .where((l) => l.estado.toLowerCase() == 'perdido')
            .length,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final weekData = _getWeeklyData();
    final today = DateTime.now().weekday - 1; // 0=Lun

    // Calcular máximo para el eje Y
    int maxVal = 1;
    for (final d in weekData) {
      final sum = (d['open'] ?? 0) + (d['done'] ?? 0) + (d['lost'] ?? 0);
      if (sum > maxVal) maxVal = sum;
    }

    // Totales de la semana
    final totalOpen =
        weekData.fold(0, (s, d) => s + (d['open'] ?? 0));
    final totalDone =
        weekData.fold(0, (s, d) => s + (d['done'] ?? 0));
    final totalLost =
        weekData.fold(0, (s, d) => s + (d['lost'] ?? 0));
    final totalSemana = totalOpen + totalDone + totalLost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Esta semana',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textDark),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalSemana leads',
                  style: const TextStyle(
                      color: _blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Gráfica de barras ────────────────────────────────────────
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: (maxVal + 1).toDouble(),
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: _divider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        final isToday = i == today;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _dayLabels[i],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isToday ? _blue : _textGrey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (v, _) => v == v.floorToDouble()
                          ? Text(
                              v.toInt().toString(),
                              style: const TextStyle(
                                  fontSize: 10, color: _textGrey),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: List.generate(7, (i) {
                  final d = weekData[i];
                  final isToday = i == today;

                  // Barras apiladas por estado
                  final open = _showOpen ? (d['open'] ?? 0).toDouble() : 0.0;
                  final done = _showDone ? (d['done'] ?? 0).toDouble() : 0.0;
                  final lost = _showLost ? (d['lost'] ?? 0).toDouble() : 0.0;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: open + done + lost,
                        width: 20,
                        borderRadius: BorderRadius.circular(6),
                        rodStackItems: [
                          if (_showOpen)
                            BarChartRodStackItem(0, open, _amber),
                          if (_showDone)
                            BarChartRodStackItem(open, open + done, _green),
                          if (_showLost)
                            BarChartRodStackItem(
                                open + done, open + done + lost, _red),
                        ],
                        color: Colors.transparent,
                        backDrawRodData: BackgroundBarChartRodData(
                          show: isToday,
                          toY: (maxVal + 1).toDouble(),
                          color: _blue.withValues(alpha: 0.04),
                        ),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => _textDark,
                    getTooltipItem: (group, _, rod, __) {
                      final i = group.x;
                      final d = weekData[i];
                      final lines = <String>[];
                      if (_showOpen && (d['open'] ?? 0) > 0)
                        lines.add('Abierto: ${d['open']}');
                      if (_showDone && (d['done'] ?? 0) > 0)
                        lines.add('Completado: ${d['done']}');
                      if (_showLost && (d['lost'] ?? 0) > 0)
                        lines.add('Perdido: ${d['lost']}');
                      if (lines.isEmpty) return null;
                      return BarTooltipItem(
                        '${_dayLabels[i]}\n${lines.join('\n')}',
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
          const SizedBox(height: 12),

          // ── Leyenda con toggles ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendToggle('Abierto', _amber, _showOpen,
                  () => setState(() => _showOpen = !_showOpen)),
              const SizedBox(width: 12),
              _legendToggle('Completado', _green, _showDone,
                  () => setState(() => _showDone = !_showDone)),
              const SizedBox(width: 12),
              _legendToggle('Perdido', _red, _showLost,
                  () => setState(() => _showLost = !_showLost)),
            ],
          ),
          const SizedBox(height: 12),

          // ── Resumen de totales ────────────────────────────────────────
          if (totalSemana > 0)
            Row(children: [
              _totalChip('$totalOpen', 'Abiertos', _amber),
              const SizedBox(width: 8),
              _totalChip('$totalDone', 'Completados', _green),
              const SizedBox(width: 8),
              _totalChip('$totalLost', 'Perdidos', _red),
            ]),
        ],
      ),
    );
  }

  Widget _legendToggle(
      String label, Color color, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: active ? 1.0 : 0.35,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
        ]),
      ),
    );
  }

  Widget _totalChip(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: _textGrey)),
          ]),
        ),
      );
}
