import 'package:flutter/material.dart';
import 'crear_formulario.dart';
import 'models/prospecto.dart';
import 'models/lead.dart';
import 'views/bitacora_screen.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:rapilead/main.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Colores (reutilizados del diseño) ───────────────────────────────────────
class _C {
  static const blue = Color(0xFF3B82F6);
  static const bgPage = Color(0xFFF0F4FF);
  static const bgCard = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF0F172A);
  static const textMedium = Color(0xFF475569);
  static const textGrey = Color(0xFF94A3B8);
  static const divider = Color(0xFFE2E8F0);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const purple = Color(0xFF8B5CF6);
}

// ─── Shell con bottom nav ────────────────────────────────────────────────────
class Dashboardp extends StatefulWidget {
  const Dashboardp({super.key});

  @override
  State<Dashboardp> createState() => _DashboardpState();
}

class _DashboardpState extends State<Dashboardp> {
  int _tabIndex = 0;

  List<Prospecto> prospectos = [];
  List<Lead> leads = [];

  void _addProspecto(Prospecto p) => setState(() => prospectos.add(p));
  void _addLead(Lead l) => setState(() => leads.add(l));

  @override
  Widget build(BuildContext context) {
    final pages = [
      InicioScreen(prospectos: prospectos, leads: leads),
      ProspectosScreen(
          prospectos: prospectos, handleOnCreateProspecto: _addProspecto),
      LeadsScreen(leads: leads, handleOnCreateLead: _addLead),
      const BitacoraTabScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      backgroundColor: _C.bgPage,
      body: IndexedStack(index: _tabIndex, children: pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
      ),
      floatingActionButton: (_tabIndex == 0 || _tabIndex == 1 || _tabIndex == 2)
          ? MiFAB(
              handleOnCreateProspecto: _addProspecto,
              handleOnCreateLead: _addLead,
            )
          : null,
    );
  }
}

// ─── Bottom Navigation Bar ───────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, Icons.home_rounded, 'Inicio'),
      (Icons.person_add_outlined, Icons.person_add_rounded, 'Prospectos'),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Leads'),
      (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Bitácora'),
      (Icons.person_outline, Icons.person_rounded, 'Perfil'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: _C.bgCard,
        border: Border(top: BorderSide(color: _C.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final sel = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        sel ? items[i].$2 : items[i].$1,
                        color: sel ? _C.blue : _C.textGrey,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].$3,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          color: sel ? _C.blue : _C.textGrey,
                        ),
                      ),
                      if (sel) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: _C.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Inicio (Home) ────────────────────────────────────────────────────────────
class InicioScreen extends StatelessWidget {
  final List<Prospecto> prospectos;
  final List<Lead> leads;

  const InicioScreen(
      {super.key, required this.prospectos, required this.leads});

  @override
  Widget build(BuildContext context) {
    final visitasHoy =
        leads.where((l) => l.estado.toLowerCase() == 'abierto').length;

    return Scaffold(
      backgroundColor: _C.bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Saludo ─────────────────────────────────────────────
              Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _C.blue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('JM',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Buenos días',
                          style: TextStyle(color: _C.textGrey, fontSize: 13)),
                      Text('Juan Martínez',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _C.textDark)),
                    ]),
                const Spacer(),
                Stack(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _C.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.divider, width: 1.5),
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        color: _C.textMedium, size: 20),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: _C.red, shape: BoxShape.circle),
                    ),
                  ),
                ]),
              ]),
              const SizedBox(height: 24),

              // ── KPI chips ──────────────────────────────────────────
              Row(children: [
                _kpiCard('${prospectos.length}', 'Prospectos'),
                const SizedBox(width: 12),
                _kpiCard('${leads.length}', 'Leads activos'),
                const SizedBox(width: 12),
                _kpiCard('$visitasHoy', 'Visitas hoy'),
              ]),
              const SizedBox(height: 24),

              // ── Cuatro módulos ─────────────────────────────────────
              Row(children: [
                Expanded(
                  child: _moduleCard(
                    icon: Icons.person_add_outlined,
                    iconColor: _C.blue,
                    iconBg: _C.blue.withValues(alpha: 0.10),
                    title: 'Prospectos',
                    subtitle: '${prospectos.length} registros',
                    selected: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _moduleCard(
                    icon: Icons.bar_chart_rounded,
                    iconColor: _C.textMedium,
                    iconBg: _C.textMedium.withValues(alpha: 0.08),
                    title: 'Leads',
                    subtitle: '${leads.length} activos',
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _moduleCard(
                    icon: Icons.menu_book_outlined,
                    iconColor: _C.green,
                    iconBg: _C.green.withValues(alpha: 0.10),
                    title: 'Bitácoras',
                    subtitle: '18 entradas',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _moduleCard(
                    icon: Icons.insert_chart_outlined_rounded,
                    iconColor: _C.purple,
                    iconBg: _C.purple.withValues(alpha: 0.10),
                    title: 'Reportes',
                    subtitle: 'Semana actual',
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Actividad reciente ─────────────────────────────────
              const Row(children: [
                Text('Actividad reciente',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark)),
                Spacer(),
                Text('Ver todo',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _C.blue)),
              ]),
              const SizedBox(height: 12),
              _activityItem(
                  icon: Icons.phone_outlined,
                  iconColor: _C.blue,
                  title: 'Tecno Soluciones S.A.',
                  subtitle: 'Llamada — acuerdo de piloto',
                  time: '09:24'),
              _activityItem(
                  icon: Icons.location_on_outlined,
                  iconColor: _C.green,
                  title: 'Constructora del Norte',
                  subtitle: 'Visita presencial registrada',
                  time: 'Ayer'),
              _activityItem(
                  icon: Icons.mail_outline_rounded,
                  iconColor: _C.purple,
                  title: 'Farmacia Central',
                  subtitle: 'Cotización enviada por correo',
                  time: 'Lun'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiCard(String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: _C.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.divider),
          ),
          child: Column(children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: _C.blue)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: _C.textGrey)),
          ]),
        ),
      );

  Widget _moduleCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    bool selected = false,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _C.blue : _C.divider,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: _C.textGrey)),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerRight,
            child:
                Icon(Icons.arrow_forward_rounded, size: 16, color: _C.textGrey),
          ),
        ]),
      );

  Widget _activityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _C.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.divider),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: _C.textGrey)),
            ]),
          ),
          Text(time,
              style: const TextStyle(
                  fontSize: 12,
                  color: _C.textGrey,
                  fontWeight: FontWeight.w500)),
        ]),
      );
}

// ─── Prospectos ───────────────────────────────────────────────────────────────
class ProspectosScreen extends StatefulWidget {
  final List<Prospecto> prospectos;
  final Function(Prospecto) handleOnCreateProspecto;

  const ProspectosScreen(
      {super.key,
      required this.prospectos,
      required this.handleOnCreateProspecto});

  @override
  State<ProspectosScreen> createState() => _ProspectosScreenState();
}

class _ProspectosScreenState extends State<ProspectosScreen> {
  String _query = '';
  String _filtroTab = 'Todos';
  final _tabs = ['Todos', 'Activos', 'Nuevos', 'Inactivos'];

  List<Prospecto> get _filtered {
    return widget.prospectos.where((p) {
      final q = _query.toLowerCase();
      return p.nombre.toLowerCase().contains(q) ||
          p.compania.toLowerCase().contains(q) ||
          p.telefono.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: _C.bgPage,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gestión',
                          style: TextStyle(fontSize: 12, color: _C.textGrey)),
                      Text('Prospectos',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: _C.textDark)),
                    ]),
                const Spacer(),
                _addButton(context),
              ]),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _searchBar('Nombre, empresa, teléfono...', (v) {
                setState(() => _query = v);
              }),
            ),
            const SizedBox(height: 12),
            _filterTabs(
                _tabs, _filtroTab, (t) => setState(() => _filtroTab = t)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('${list.length} registros encontrados',
                  style: const TextStyle(fontSize: 13, color: _C.textGrey)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? _emptyState('No hay prospectos registrados')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) => _prospectoCard(list[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prospectoCard(Prospecto p) {
    final initials = _initials(p.compania);
    final color = _colorFromInitials(initials);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.divider),
      ),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(initials,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nombre,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.textDark)),
            const SizedBox(height: 2),
            Text(p.compania,
                style: const TextStyle(fontSize: 12, color: _C.textGrey)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.phone_outlined, size: 12, color: _C.textGrey),
              const SizedBox(width: 4),
              Text(p.telefono,
                  style: const TextStyle(fontSize: 12, color: _C.textGrey)),
            ]),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _statusChip('Activo', _C.green),
          const SizedBox(height: 8),
          Row(children: [
            GestureDetector(
              onTap: () => _llamar(p.telefono),
              child: _iconAction(Icons.phone_outlined, _C.green),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _enviarCorreo(p.correo, nombre: p.nombre),
              child: _iconAction(Icons.mail_outline_rounded, _C.blue),
            ),
          ]),
        ]),
      ]),
    );
  }
}

// ─── Leads ────────────────────────────────────────────────────────────────────
class LeadsScreen extends StatefulWidget {
  final List<Lead> leads;
  final Function(Lead) handleOnCreateLead;

  const LeadsScreen(
      {super.key, required this.leads, required this.handleOnCreateLead});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  String _query = '';
  String _filtroTab = 'Todos';
  final _tabs = ['Todos', 'Abierto', 'Completado', 'Perdido'];

  List<Lead> get _filtered {
    return widget.leads.where((l) {
      final q = _query.toLowerCase();
      final matchQ = l.nameprospecto.toLowerCase().contains(q) ||
          l.infoprospecto.toLowerCase().contains(q) ||
          l.estado.toLowerCase().contains(q);
      final matchTab = _filtroTab == 'Todos' ||
          l.estado.toLowerCase() == _filtroTab.toLowerCase();
      return matchQ && matchTab;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: _C.bgPage,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Oportunidades',
                          style: TextStyle(fontSize: 12, color: _C.textGrey)),
                      Text('Leads',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: _C.textDark)),
                    ]),
                const Spacer(),
                _addButton(context),
              ]),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _searchBar('Lead, empresa, estado...', (v) {
                setState(() => _query = v);
              }),
            ),
            const SizedBox(height: 12),
            _filterTabs(
                _tabs, _filtroTab, (t) => setState(() => _filtroTab = t)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('${list.length} leads activos',
                  style: const TextStyle(fontSize: 13, color: _C.textGrey)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? _emptyState('No hay leads registrados')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) => _leadCard(ctx, list[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leadCard(BuildContext context, Lead l) {
    final initials = _initials(l.nameprospecto);
    final color = _colorFromInitials(initials);
    final estadoColor = _estadoColor(l.estado);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BitacoraScreen(nombreLead: l.nameprospecto),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.divider),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(initials,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.nameprospecto,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark)),
              const SizedBox(height: 2),
              Text(l.infoprospecto.isEmpty ? l.nameprospecto : l.infoprospecto,
                  style: const TextStyle(fontSize: 12, color: _C.textGrey)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 11, color: _C.textGrey),
                const SizedBox(width: 4),
                Text(l.fecha.isEmpty ? '—' : l.fecha,
                    style: const TextStyle(fontSize: 11, color: _C.textGrey)),
              ]),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _statusChip(l.estado, estadoColor),
            const SizedBox(height: 8),
            Row(children: [
              GestureDetector(
                onTap: () => _llamar(l.telefono),
                child: _iconAction(Icons.phone_outlined, _C.green),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _enviarCorreo(l.correo, nombre: l.nameprospecto),
                child: _iconAction(Icons.mail_outline_rounded, _C.blue),
              ),
            ]),
          ]),
        ]),
      ),
    );
  }

  Color _estadoColor(String e) {
    switch (e.toLowerCase()) {
      case 'completado':
        return _C.green;
      case 'abierto':
        return _C.amber;
      case 'perdido':
        return _C.red;
      default:
        return _C.textGrey;
    }
  }
}

// ─── Bitácora tab (placeholder) ───────────────────────────────────────────────
class BitacoraTabScreen extends StatelessWidget {
  const BitacoraTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _C.bgPage,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registro',
                  style: TextStyle(fontSize: 12, color: _C.textGrey)),
              Text('Bitácora',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _C.textDark)),
              SizedBox(height: 40),
              Center(
                child: Text('Selecciona un lead para ver su bitácora.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _C.textGrey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Perfil tab (placeholder) ─────────────────────────────────────────────────
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgPage,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mi cuenta',
                  style: TextStyle(fontSize: 12, color: _C.textGrey)),
              const Text('Perfil',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _C.textDark)),
              const SizedBox(height: 24),
              Center(
                child: Column(children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _C.blue,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Text('JM',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Juan Martínez',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _C.textDark)),
                  const Text('Vendedor',
                      style: TextStyle(fontSize: 13, color: _C.textGrey)),
                ]),
              ),
              const SizedBox(height: 32),
              _profileItem(Icons.mail_outline_rounded, 'admin@admin.com'),
              _profileItem(Icons.phone_outlined, '+504 9876-5432'),
              _profileItem(Icons.business_outlined, 'RapiLead Corp.'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await SessionManager.clearSession();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.red.withValues(alpha: 0.08),
                    foregroundColor: _C.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileItem(IconData icon, String text) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _C.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.divider),
        ),
        child: Row(children: [
          Icon(icon, color: _C.blue, size: 20),
          const SizedBox(width: 12),
          Text(text,
              style: const TextStyle(
                  fontSize: 14,
                  color: _C.textDark,
                  fontWeight: FontWeight.w500)),
        ]),
      );
}

// ─── FAB ──────────────────────────────────────────────────────────────────────
class MiFAB extends StatelessWidget {
  final Function(Prospecto) handleOnCreateProspecto;
  final Function(Lead) handleOnCreateLead;

  const MiFAB({
    super.key,
    required this.handleOnCreateProspecto,
    required this.handleOnCreateLead,
  });

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: _C.blue,
      foregroundColor: Colors.white,
      spaceBetweenChildren: 8,
      children: [
        // Botón para crear Lead
        SpeedDialChild(
          child: const Icon(Icons.bar_chart_rounded),
          label: 'Agregar Lead',
          backgroundColor: _C.blue,
          foregroundColor: Colors.white,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CrearPersonaForm(
                  isProspecto: false,
                  // Solo pasamos la función, eliminamos el .then()
                  handleOnCreateLead: handleOnCreateLead, 
                ),
              ),
            );
          },
        ),
        
        // Botón para crear Prospecto
        SpeedDialChild(
          child: const Icon(Icons.person_add_rounded),
          label: 'Agregar Prospecto',
          backgroundColor: _C.green, 
          foregroundColor: Colors.white,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CrearPersonaForm(
                  isProspecto: true,
                  // Solo pasamos la función, eliminamos el .then()
                  handleOnCreateProspecto: handleOnCreateProspecto,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Helpers de UI ────────────────────────────────────────────────────────────

Widget _searchBar(String hint, ValueChanged<String> onChanged) => TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _C.textGrey, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: _C.textGrey, size: 20),
        filled: true,
        fillColor: _C.bgCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.blue, width: 1.8),
        ),
      ),
    );

Widget _filterTabs(
        List<String> tabs, String selected, ValueChanged<String> onTap) =>
    SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tabs.length,
        itemBuilder: (_, i) {
          final sel = tabs[i] == selected;
          return GestureDetector(
            onTap: () => onTap(tabs[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? _C.blue : _C.bgCard,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: sel ? _C.blue : _C.divider, width: 1.5),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? Colors.white : _C.textMedium,
                ),
              ),
            ),
          );
        },
      ),
    );

Widget _statusChip(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );

Widget _iconAction(IconData icon, Color color) => Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    );

Widget _addButton(BuildContext context) => Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _C.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 22),
    );

Widget _emptyState(String msg) => Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.inbox_outlined, size: 48, color: _C.textGrey),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: _C.textGrey, fontSize: 15)),
      ]),
    );

// ─── Utilidades ───────────────────────────────────────────────────────────────
String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

Color _colorFromInitials(String initials) {
  final colors = [
    _C.blue,
    _C.green,
    _C.amber,
    _C.red,
    _C.purple,
    const Color(0xFF0891B2),
    const Color(0xFF7C3AED),
  ];
  final idx = initials.codeUnitAt(0) % colors.length;
  return colors[idx];
}

Future<void> _llamar(String telefono) async {
  final uri = Uri(scheme: 'tel', path: telefono);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> _enviarCorreo(String email, {String? nombre}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: {
      'subject': 'Seguimiento RapiLead${nombre != null ? " - $nombre" : ""}',
      'body': 'Hola${nombre != null ? " $nombre" : ""},\n\n',
    },
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
