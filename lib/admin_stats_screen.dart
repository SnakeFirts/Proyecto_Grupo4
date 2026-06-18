// lib/admin_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'models/prospecto.dart';
import 'models/lead.dart';
import 'services/firestore_service.dart';

// ─── Colores ──────────────────────────────────────────────────────────────────
class _C {
  static const blue = Color(0xFF3B82F6);
  static const bgPage = Color(0xFFF0F4FF);
  static const bgCard = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF0F172A);
  static const textGrey = Color(0xFF94A3B8);
  static const divider = Color(0xFFE2E8F0);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const purple = Color(0xFF8B5CF6);
}

// ─── Modelo de usuario ────────────────────────────────────────────────────────
class UsuarioApp {
  final String uid;
  final String nombre;
  final String email;
  final String rol;

  const UsuarioApp({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  factory UsuarioApp.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UsuarioApp(
      uid: doc.id,
      nombre: d['nombre'] ?? 'Sin nombre',
      email: d['email'] ?? '',
      rol: d['rol'] ?? 'Vendedor',
    );
  }
}

// ─── Pantalla Admin Inicio ────────────────────────────────────────────────────
class AdminInicioScreen extends StatelessWidget {
  final List<Prospecto> prospectos;
  final List<Lead> leads;

  const AdminInicioScreen({
    super.key,
    required this.prospectos,
    required this.leads,
  });

  @override
  Widget build(BuildContext context) {
    final totalProspectos = prospectos.length;
    final totalLeads = leads.length;
    final leadsAbiertos =
        leads.where((l) => l.estado.toLowerCase() == 'abierto').length;
    final leadsCompletados =
        leads.where((l) => l.estado.toLowerCase() == 'completado').length;
    final leadsPerdidos =
        leads.where((l) => l.estado.toLowerCase() == 'perdido').length;

    final hoy = DateTime.now();
    final leadsHoy = leads.where((l) {
      return l.fecha != null &&
          l.fecha!.year == hoy.year &&
          l.fecha!.month == hoy.month &&
          l.fecha!.day == hoy.day;
    }).length;

    final tasaConversion =
        totalLeads > 0 ? (leadsCompletados / totalLeads * 100) : 0.0;

    // ── Leads creados por día (últimos 7 días) ────────────────────────
    final Map<int, int> leadsPorDia = {};
    for (int i = 6; i >= 0; i--) {
      final dia =
          DateTime(hoy.year, hoy.month, hoy.day).subtract(Duration(days: i));
      final count = leads.where((l) {
        final fc = l.fechaCreacion;
        if (fc == null) return false;
        return fc.year == dia.year &&
            fc.month == dia.month &&
            fc.day == dia.day;
      }).length;
      leadsPorDia[6 - i] = count;
    }

    // ── Agrupar leads y prospectos por userId ────────────────────────
    final Map<String, int> leadsPorUid = {};
    final Map<String, int> prospectosPorUid = {};
    for (final l in leads) {
      if (l.userId != null && l.userId!.isNotEmpty) {
        leadsPorUid[l.userId!] = (leadsPorUid[l.userId!] ?? 0) + 1;
      }
    }
    for (final p in prospectos) {
      if (p.userId != null && p.userId!.isNotEmpty) {
        prospectosPorUid[p.userId!] = (prospectosPorUid[p.userId!] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: _C.bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────
              Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Panel de control',
                          style: TextStyle(color: _C.textGrey, fontSize: 13)),
                      Text('Administrador',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _C.textDark)),
                    ]),
              ]),
              const SizedBox(height: 24),

              // ── Banner global ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resumen del equipo',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$totalLeads',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                height: 1)),
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text('leads totales',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      _miniStat('$totalProspectos', 'Prospectos',
                          Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(width: 8),
                      _miniStat('$leadsHoy', 'Hoy',
                          Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(width: 8),
                      _miniStat('${tasaConversion.toStringAsFixed(0)}%',
                          'Conversión', Colors.white.withValues(alpha: 0.15)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── KPI grid ─────────────────────────────────────────────
              const _SectionLabel('Estado de leads'),
              const SizedBox(height: 10),
              Row(children: [
                _kpiCard('$leadsAbiertos', 'Abiertos', _C.amber,
                    Icons.radio_button_unchecked_rounded),
                const SizedBox(width: 10),
                _kpiCard('$leadsCompletados', 'Completados', _C.green,
                    Icons.check_circle_outline_rounded),
                const SizedBox(width: 10),
                _kpiCard('$leadsPerdidos', 'Perdidos', _C.red,
                    Icons.cancel_outlined),
              ]),
              const SizedBox(height: 24),

              // ── Gráfica de línea ──────────────────────────────────────
              const _SectionLabel('Leads creados — últimos 7 días'),
              const SizedBox(height: 10),
              _LineChart(leadsPorDia: leadsPorDia),
              const SizedBox(height: 24),

              // ── Gráfica de barras con nombres reales ──────────────────
              // FIX: Usamos FutureBuilder para resolver nombres desde Firestore
              const _SectionLabel('Prospectos vs Leads por vendedor'),
              const SizedBox(height: 10),
              _BarChartConNombres(
                leadsPorUid: leadsPorUid,
                prospectosPorUid: prospectosPorUid,
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 24),

              // ── Gráfica de kilómetros por vendedor ───────────────────
              const _SectionLabel('Kilómetros recorridos por vendedor'),
              const SizedBox(height: 10),
              const _KmChartConNombres(),
              const SizedBox(height: 24),

              // ── Barra de distribución ─────────────────────────────────
              if (totalLeads > 0) ...[
                const _SectionLabel('Distribución de estados'),
                const SizedBox(height: 10),
                _EstadoBar(
                  abiertos: leadsAbiertos,
                  completados: leadsCompletados,
                  perdidos: leadsPerdidos,
                  total: totalLeads,
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label, Color bg) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
      );

  Widget _kpiCard(String value, String label, Color color, IconData icon) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: _C.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.divider),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: _C.textGrey)),
          ]),
        ),
      );
}

// ─── FIX: Bar chart con nombres reales via Firestore ─────────────────────────
// Resuelve los UIDs a nombres reales antes de renderizar
class _BarChartConNombres extends StatefulWidget {
  final Map<String, int> leadsPorUid;
  final Map<String, int> prospectosPorUid;

  const _BarChartConNombres({
    required this.leadsPorUid,
    required this.prospectosPorUid,
  });

  @override
  State<_BarChartConNombres> createState() => _BarChartConNombresState();
}

class _BarChartConNombresState extends State<_BarChartConNombres> {
  Map<String, String> _nombres = {}; // uid → nombre corto
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _resolverNombres();
  }

  @override
  void didUpdateWidget(_BarChartConNombres old) {
    super.didUpdateWidget(old);
    // Si cambian los UIDs, volver a resolver
    final uidsNuevos = {
      ...widget.leadsPorUid.keys,
      ...widget.prospectosPorUid.keys
    };
    final uidsViejos = {...old.leadsPorUid.keys, ...old.prospectosPorUid.keys};
    if (uidsNuevos.length != uidsViejos.length ||
        !uidsNuevos.every(uidsViejos.contains)) {
      _resolverNombres();
    }
  }

  Future<void> _resolverNombres() async {
    final uids = {
      ...widget.leadsPorUid.keys,
      ...widget.prospectosPorUid.keys,
    };
    if (uids.isEmpty) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    final Map<String, String> nombres = {};
    // Consultar en batches de 10 (límite de whereIn en Firestore)
    final uidList = uids.toList();
    for (int i = 0; i < uidList.length; i += 10) {
      final batch =
          uidList.sublist(i, i + 10 > uidList.length ? uidList.length : i + 10);
      try {
        final snap = await FirebaseFirestore.instance
            .collection('usuarios')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          final nombreCompleto = (data['nombre'] as String? ?? '').trim();
          // Primera palabra del nombre, máx 8 chars
          final partes = nombreCompleto.split(' ');
          final primerNombre = partes.isNotEmpty ? partes[0] : doc.id;
          nombres[doc.id] = primerNombre.length > 8
              ? primerNombre.substring(0, 8)
              : primerNombre;
        }
      } catch (_) {
        // Si falla, usar primeras 6 letras del UID como fallback
        for (final uid in batch) {
          nombres[uid] = uid.length >= 6 ? uid.substring(0, 6) : uid;
        }
      }
    }

    if (mounted) {
      setState(() {
        _nombres = nombres;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: _C.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.divider),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: _C.blue, strokeWidth: 2),
        ),
      );
    }

    return _BarChart(
      leadsPorUid: widget.leadsPorUid,
      prospectosPorUid: widget.prospectosPorUid,
      nombresResueltos: _nombres,
    );
  }
}

// ─── Gráfica de línea: leads creados por día ─────────────────────────────────
class _LineChart extends StatelessWidget {
  final Map<int, int> leadsPorDia;

  const _LineChart({required this.leadsPorDia});

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final spots = List.generate(7, (i) {
      return FlSpot(i.toDouble(), (leadsPorDia[i] ?? 0).toDouble());
    });

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY < 1 ? 3 : maxY + 1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: _C.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (v, _) => v == v.floorToDouble()
                          ? Text(
                              v.toInt().toString(),
                              style: const TextStyle(
                                  fontSize: 10, color: _C.textGrey),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final dia = DateTime(hoy.year, hoy.month, hoy.day)
                            .subtract(Duration(days: 6 - v.toInt()));
                        const dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dias[dia.weekday - 1],
                            style: const TextStyle(
                                fontSize: 11, color: _C.textGrey),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _C.blue,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: _C.blue,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _C.blue.withValues(alpha: 0.2),
                          _C.blue.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                    color: _C.blue, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('Leads creados',
                style: TextStyle(fontSize: 11, color: _C.textGrey)),
          ]),
        ],
      ),
    );
  }
}

// ─── Gráfica de barras: prospectos vs leads — con nombres reales ──────────────
class _BarChart extends StatelessWidget {
  final Map<String, int> leadsPorUid;
  final Map<String, int> prospectosPorUid;
  final Map<String, String> nombresResueltos;

  const _BarChart({
    required this.leadsPorUid,
    required this.prospectosPorUid,
    required this.nombresResueltos,
  });

  @override
  Widget build(BuildContext context) {
    final uids = {...leadsPorUid.keys, ...prospectosPorUid.keys}.toList();

    if (uids.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _C.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.divider),
        ),
        child: const Center(
          child: Text('Sin datos de vendedores aún',
              style: TextStyle(color: _C.textGrey)),
        ),
      );
    }

    // Nombre legible en vez de UID truncado
    final labels = uids
        .map((u) =>
            nombresResueltos[u] ?? (u.length > 6 ? u.substring(0, 6) : u))
        .toList();

    final maxY = uids.map((u) {
      final l = (leadsPorUid[u] ?? 0).toDouble();
      final p = (prospectosPorUid[u] ?? 0).toDouble();
      return l > p ? l : p;
    }).reduce((a, b) => a > b ? a : b);

    final barGroups = List.generate(uids.length, (i) {
      final uid = uids[i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: (prospectosPorUid[uid] ?? 0).toDouble(),
            color: _C.green,
            width: 12,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: (leadsPorUid[uid] ?? 0).toDouble(),
            color: _C.blue,
            width: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        barsSpace: 4,
      );
    });

    final needsScroll = uids.length > 5;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: needsScroll
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: uids.length * 60.0,
                      child: _buildBarChart(barGroups, labels, maxY),
                    ),
                  )
                : _buildBarChart(barGroups, labels, maxY),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendDot(_C.green, 'Prospectos'),
            const SizedBox(width: 16),
            _legendDot(_C.blue, 'Leads'),
          ]),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    List<BarChartGroupData> barGroups,
    List<String> labels,
    double maxY,
  ) {
    return BarChart(
      BarChartData(
        maxY: maxY < 1 ? 3 : maxY + 1,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: _C.divider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[i],
                    style: const TextStyle(fontSize: 10, color: _C.textGrey),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (v, _) => v == v.floorToDouble()
                  ? Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: _C.textGrey),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: barGroups,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => _C.textDark,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final uid = {...leadsPorUid.keys, ...prospectosPorUid.keys}
                  .toList()[groupIndex];
              final nombre = nombresResueltos[uid] ?? uid;
              final tipo = rodIndex == 0 ? 'Prospectos' : 'Leads';
              return BarTooltipItem(
                '$nombre\n$tipo: ${rod.toY.toInt()}',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: _C.textGrey)),
      ]);
}

// ─── Gráfica de barras: kilómetros por vendedor ──────────────────────────────
class _KmChartConNombres extends StatefulWidget {
  const _KmChartConNombres();

  @override
  State<_KmChartConNombres> createState() => _KmChartConNombresState();
}

class _KmChartConNombresState extends State<_KmChartConNombres> {
  Map<String, double> _kmPorUsuario = {};
  Map<String, String> _nombres = {};
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final servicio = FirestoreService();
      final kmData = await servicio.obtenerKilometrosPorUsuario();

      // Resolver nombres desde Firestore
      final Map<String, String> nombres = {};
      final uidList = kmData.keys.toList();
      for (int i = 0; i < uidList.length; i += 10) {
        final batch = uidList.sublist(
            i, i + 10 > uidList.length ? uidList.length : i + 10);
        try {
          final snap = await FirebaseFirestore.instance
              .collection('usuarios')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          for (final doc in snap.docs) {
            final data = doc.data();
            final nombreCompleto = (data['nombre'] as String? ?? '').trim();
            final partes = nombreCompleto.split(' ');
            final primerNombre = partes.isNotEmpty ? partes[0] : doc.id;
            nombres[doc.id] = primerNombre.length > 10
                ? primerNombre.substring(0, 10)
                : primerNombre;
          }
        } catch (_) {
          for (final uid in batch) {
            nombres[uid] = uid.length >= 6 ? uid.substring(0, 6) : uid;
          }
        }
      }

      if (mounted) {
        setState(() {
          _kmPorUsuario = kmData;
          _nombres = nombres;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: _C.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.divider),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: _C.purple, strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _C.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.divider),
        ),
        child: Center(
          child: Text('Error al cargar km: $_error',
              style: const TextStyle(color: _C.red, fontSize: 12)),
        ),
      );
    }

    final entries = _kmPorUsuario.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _C.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.divider),
        ),
        child: const Center(
          child: Text('Sin datos de kilómetros aún',
              style: TextStyle(color: _C.textGrey)),
        ),
      );
    }

    final labels = entries
        .map((e) =>
            _nombres[e.key] ??
            (e.key.length > 6 ? e.key.substring(0, 6) : e.key))
        .toList();
    final values = entries.map((e) => e.value).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b);

    final barGroups = List.generate(entries.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: values[i],
            color: _C.purple,
            width: 16,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY < 1 ? 10 : maxY + 5,
              color: _C.purple.withValues(alpha: 0.06),
            ),
          ),
        ],
      );
    });

    final needsScroll = entries.length > 5;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: needsScroll
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: entries.length * 60.0,
                      child: _buildKmChart(barGroups, labels, maxY, entries),
                    ),
                  )
                : _buildKmChart(barGroups, labels, maxY, entries),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                    color: _C.purple, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('Kilómetros recorridos',
                style: TextStyle(fontSize: 11, color: _C.textGrey)),
          ]),
          const SizedBox(height: 8),
          // Resumen debajo del gráfico
          ...entries.map((e) {
            final nombre = _nombres[e.key] ??
                (e.key.length > 6 ? e.key.substring(0, 6) : e.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: _C.purple, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(nombre,
                          style: const TextStyle(
                              fontSize: 12, color: _C.textDark))),
                  Text('${e.value.toStringAsFixed(1)} km',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.purple)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildKmChart(
    List<BarChartGroupData> barGroups,
    List<String> labels,
    double maxY,
    List<MapEntry<String, double>> entries,
  ) {
    return BarChart(
      BarChartData(
        maxY: maxY < 1 ? 10 : maxY + 5,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: _C.divider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[i],
                    style: const TextStyle(fontSize: 10, color: _C.textGrey),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval:
                  (maxY / 5).ceilToDouble() < 1 ? 1 : (maxY / 5).ceilToDouble(),
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: _C.textGrey),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: barGroups,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => _C.textDark,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final nombre = _nombres[entries[groupIndex].key] ?? 'Vendedor';
              return BarTooltipItem(
                '$nombre\n${rod.toY.toStringAsFixed(1)} km',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Barra de distribución de estados ────────────────────────────────────────
class _EstadoBar extends StatelessWidget {
  final int abiertos, completados, perdidos, total;

  const _EstadoBar({
    required this.abiertos,
    required this.completados,
    required this.perdidos,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pA = abiertos / total;
    final pC = completados / total;
    final pP = perdidos / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
      ),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(children: [
              if (pA > 0)
                Expanded(
                    flex: (pA * 100).round(),
                    child: Container(color: _C.amber)),
              if (pC > 0)
                Expanded(
                    flex: (pC * 100).round(),
                    child: Container(color: _C.green)),
              if (pP > 0)
                Expanded(
                    flex: (pP * 100).round(), child: Container(color: _C.red)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _legend(_C.amber, 'Abiertos', '${(pA * 100).round()}%'),
          _legend(_C.green, 'Completados', '${(pC * 100).round()}%'),
          _legend(_C.red, 'Perdidos', '${(pP * 100).round()}%'),
        ]),
      ]),
    );
  }

  Widget _legend(Color color, String label, String pct) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pct,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: _C.textGrey, fontSize: 10)),
        ]),
      ]);
}

// ─── Pantalla de equipo (solo Admin) ─────────────────────────────────────────
class EquipoScreen extends StatelessWidget {
  final List<Lead> leads;
  final List<Prospecto> prospectos;

  const EquipoScreen({
    super.key,
    required this.leads,
    required this.prospectos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgPage,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gestión',
                      style: TextStyle(fontSize: 12, color: _C.textGrey)),
                  Text('Equipo',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _C.textDark)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: _C.blue));
                  }

                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No hay usuarios registrados',
                            style: TextStyle(color: _C.textGrey)));
                  }

                  final usuarios =
                      snap.data!.docs.map(UsuarioApp.fromDoc).toList();

                  final Map<String, int> leadsPorUid = {};
                  final Map<String, int> prospectosPorUid = {};

                  for (final l in leads) {
                    if (l.userId != null) {
                      leadsPorUid[l.userId!] =
                          (leadsPorUid[l.userId!] ?? 0) + 1;
                    }
                  }
                  for (final p in prospectos) {
                    if (p.userId != null) {
                      prospectosPorUid[p.userId!] =
                          (prospectosPorUid[p.userId!] ?? 0) + 1;
                    }
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      Row(children: [
                        _resumenChip('${usuarios.length}', 'Usuarios', _C.blue),
                        const SizedBox(width: 8),
                        _resumenChip(
                            '${usuarios.where((u) => u.rol == "Administrador").length}',
                            'Admins',
                            _C.purple),
                        const SizedBox(width: 8),
                        _resumenChip(
                            '${usuarios.where((u) => u.rol == "Vendedor").length}',
                            'Vendedores',
                            _C.green),
                      ]),
                      const SizedBox(height: 16),
                      ...usuarios.map((u) => _usuarioCard(
                            u,
                            leadsPorUid[u.uid] ?? 0,
                            prospectosPorUid[u.uid] ?? 0,
                          )),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumenChip(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: _C.textGrey)),
          ]),
        ),
      );

  Widget _usuarioCard(UsuarioApp u, int leads, int prospectos) {
    final isAdmin = u.rol == 'Administrador';
    final rolColor = isAdmin ? _C.purple : _C.blue;
    final initials = _initials(u.nombre);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: rolColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(initials,
                    style: TextStyle(
                        color: rolColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.nombre,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _C.textDark)),
                    Text(u.email,
                        style:
                            const TextStyle(fontSize: 12, color: _C.textGrey),
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: rolColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: rolColor.withValues(alpha: 0.25)),
              ),
              child: Text(u.rol,
                  style: TextStyle(
                      color: rolColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          if (!isAdmin) ...[
            const SizedBox(height: 12),
            const Divider(color: _C.divider, height: 1),
            const SizedBox(height: 12),
            Row(children: [
              _statCell('$leads', 'Leads', _C.blue, Icons.bar_chart_rounded),
              const SizedBox(width: 8),
              _statCell('$prospectos', 'Prospectos', _C.green,
                  Icons.person_outline_rounded),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _statCell(String value, String label, Color color, IconData icon) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 16, fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(color: _C.textGrey, fontSize: 10)),
            ]),
          ]),
        ),
      );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, color: _C.textDark));
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}
