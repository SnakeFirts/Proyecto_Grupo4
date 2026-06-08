import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/prospecto.dart';
import 'models/lead.dart';
import 'services/firestore_service.dart';
import 'views/prospecto_form.dart';
import 'views/lead_form.dart';
import 'views/bitacora_screen.dart';
import 'main.dart';

// ─── Colores ──────────────────────────────────────────────────────────────────
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

// ─── Shell principal ──────────────────────────────────────────────────────────
class Dashboardp extends StatefulWidget {
  const Dashboardp({super.key});

  @override
  State<Dashboardp> createState() => _DashboardpState();
}

class _DashboardpState extends State<Dashboardp> {
  int _tabIndex = 0;
  final _svc = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Prospecto>>(
      stream: _svc.streamProspectos(),
      builder: (ctx, snapP) {
        return StreamBuilder<List<Lead>>(
          stream: _svc.streamLeads(),
          builder: (ctx, snapL) {
            final prospectos = snapP.data ?? [];
            final leads = snapL.data ?? [];

            final pages = [
              InicioScreen(prospectos: prospectos, leads: leads, svc: _svc),
              ProspectosScreen(prospectos: prospectos, svc: _svc),
              LeadsScreen(leads: leads, svc: _svc),
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
              floatingActionButton:
                  (_tabIndex == 0 || _tabIndex == 1 || _tabIndex == 2)
                      ? _MiFAB(svc: _svc)
                      : null,
            );
          },
        );
      },
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────
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
                      Icon(sel ? items[i].$2 : items[i].$1,
                          color: sel ? _C.blue : _C.textGrey, size: 24),
                      const SizedBox(height: 3),
                      Text(items[i].$3,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w400,
                            color: sel ? _C.blue : _C.textGrey,
                          )),
                      if (sel) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                              color: _C.blue, shape: BoxShape.circle),
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

// ─── Inicio ───────────────────────────────────────────────────────────────────
class InicioScreen extends StatelessWidget {
  final List<Prospecto> prospectos;
  final List<Lead> leads;
  final FirestoreService svc;

  const InicioScreen({
    super.key,
    required this.prospectos,
    required this.leads,
    required this.svc,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nombre = user?.displayName ?? user?.email?.split('@').first ?? 'Usuario';
    final initials = _initials(nombre);
    final hora = DateTime.now().hour;
    final saludo = hora < 12
        ? 'Buenos días'
        : hora < 18
            ? 'Buenas tardes'
            : 'Buenas noches';

    final leadsAbiertos = leads.where((l) => l.estado.toLowerCase() == 'abierto').length;
    final hoy = DateTime.now();
    final visitasHoy = leads.where((l) {
      return l.fecha != null &&
          l.fecha!.year == hoy.year &&
          l.fecha!.month == hoy.month &&
          l.fecha!.day == hoy.day;
    }).length;

    return Scaffold(
      backgroundColor: _C.bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _C.blue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(saludo,
                      style: const TextStyle(color: _C.textGrey, fontSize: 13)),
                  Text(nombre,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _C.textDark)),
                ]),
                const Spacer(),
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
              ]),
              const SizedBox(height: 24),

              // ── KPIs ─────────────────────────────────────────────────────
              Row(children: [
                _kpiCard('${prospectos.length}', 'Prospectos', _C.blue),
                const SizedBox(width: 10),
                _kpiCard('$leadsAbiertos', 'Leads activos', _C.amber),
                const SizedBox(width: 10),
                _kpiCard('$visitasHoy', 'Hoy', _C.green),
              ]),
              const SizedBox(height: 24),

              // ── Acceso rápido ─────────────────────────────────────────────
              const Text('Acceso rápido',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _quickCard(
                    icon: Icons.person_add_outlined,
                    label: 'Nuevo\nProspecto',
                    color: _C.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProspectoForm(firestoreService: svc),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickCard(
                    icon: Icons.bar_chart_rounded,
                    label: 'Nuevo\nLead',
                    color: _C.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LeadForm(firestoreService: svc),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickCard(
                    icon: Icons.phone_outlined,
                    label: 'Llamada\nrápida',
                    color: _C.green,
                    onTap: () => _mostrarPickerLlamada(context),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              
              Row(children: [
                const Text('Últimos leads',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark)),
                const Spacer(),
                const Text('Ver todo',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _C.blue)),
              ]),
              const SizedBox(height: 12),
              if (leads.isEmpty)
                _emptyState('No hay leads registrados')
              else
                ...leads.take(3).map((l) => _leadMiniCard(context, l, svc)),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarPickerLlamada(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Llamar a...',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _C.textDark)),
            const SizedBox(height: 12),
            if (leads.isEmpty && prospectos.isEmpty)
              const Text('No hay contactos registrados.',
                  style: TextStyle(color: _C.textGrey))
            else
              ...([
                ...prospectos.map((p) => _contactoTile(
                    p.nombre, p.telefono, Icons.person_outline_rounded)),
                ...leads.map((l) => _contactoTile(
                    l.nameprospecto, l.telefono, Icons.bar_chart_rounded)),
              ].take(8)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _contactoTile(String nombre, String tel, IconData icon) {
    if (tel.isEmpty) return const SizedBox.shrink();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _C.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _C.blue, size: 18),
      ),
      title:
          Text(nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(tel, style: const TextStyle(fontSize: 12, color: _C.textGrey)),
      trailing: GestureDetector(
        onTap: () => _llamar(tel),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _C.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.phone_rounded, color: _C.green, size: 18),
        ),
      ),
    );
  }

  Widget _kpiCard(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: _C.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.divider),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: _C.textGrey)),
          ]),
        ),
      );

  Widget _quickCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.divider),
          ),
          child: Column(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _C.textDark)),
          ]),
        ),
      );

  Widget _leadMiniCard(BuildContext context, Lead l, FirestoreService svc) {
    final initials = _initials(l.nameprospecto);
    final color = _colorFromInitials(initials);
    final estadoColor = _estadoColor(l.estado);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BitacoraScreen(lead: l, svc: svc),
        ),
      ),
      child: Container(
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(initials,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.nameprospecto,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark)),
              Text(l.infoprospecto,
                  style: const TextStyle(fontSize: 12, color: _C.textGrey)),
            ]),
          ),
          _statusChip(l.estado, estadoColor),
        ]),
      ),
    );
  }
}

// ─── Prospectos ───────────────────────────────────────────────────────────────
class ProspectosScreen extends StatefulWidget {
  final List<Prospecto> prospectos;
  final FirestoreService svc;

  const ProspectosScreen({
    super.key,
    required this.prospectos,
    required this.svc,
  });

  @override
  State<ProspectosScreen> createState() => _ProspectosScreenState();
}

class _ProspectosScreenState extends State<ProspectosScreen> {
  String _query = '';

  List<Prospecto> get _filtered {
    final q = _query.toLowerCase();
    if (q.isEmpty) return widget.prospectos;
    return widget.prospectos.where((p) {
      return p.nombre.toLowerCase().contains(q) ||
          p.compania.toLowerCase().contains(q) ||
          p.telefono.contains(q) ||
          p.correo.toLowerCase().contains(q);
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
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Gestión',
                      style: TextStyle(fontSize: 12, color: _C.textGrey)),
                  Text('Prospectos',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _C.textDark)),
                ]),
                const Spacer(),
                // Botón + funcional
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProspectoForm(firestoreService: widget.svc),
                    ),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _C.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _searchBar('Nombre, empresa, teléfono...',
                  (v) => setState(() => _query = v)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('${list.length} prospectos',
                  style: const TextStyle(fontSize: 13, color: _C.textGrey)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? _emptyState('No hay prospectos registrados')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) =>
                          _prospectoCard(ctx, list[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prospectoCard(BuildContext context, Prospecto p) {
    final initials = _initials(p.compania);
    final color = _colorFromInitials(initials);

    return Dismissible(
      key: Key(p.id ?? p.nombre),
      background: _swipeBg(
          color: _C.blue,
          icon: Icons.edit_outlined,
          label: 'Editar',
          alignment: Alignment.centerLeft),
      secondaryBackground: _swipeBg(
          color: _C.red,
          icon: Icons.delete_outline_rounded,
          label: 'Eliminar',
          alignment: Alignment.centerRight),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          // Editar
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProspectoForm(prospecto: p, firestoreService: widget.svc),
            ),
          );
          return false; // No quitar de la lista, Firestore actualiza
        } else {
          return await _confirmarEliminacion(context, 'prospecto', p.nombre);
        }
      },
      onDismissed: (dir) {
        if (dir == DismissDirection.endToStart && p.id != null) {
          widget.svc.eliminarProspecto(p.id!);
        }
      },
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
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                Text(p.telefono.isEmpty ? '—' : p.telefono,
                    style: const TextStyle(fontSize: 12, color: _C.textGrey)),
              ]),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            // Botón convertir a lead
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeadForm(
                    prospectoOrigen: p,
                    firestoreService: widget.svc,
                  ),
                ),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.purple.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.purple.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.swap_horiz_rounded,
                      color: _C.purple, size: 12),
                  const SizedBox(width: 3),
                  const Text('Lead',
                      style: TextStyle(
                          color: _C.purple,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
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
      ),
    );
  }
}

// ─── Leads ────────────────────────────────────────────────────────────────────
class LeadsScreen extends StatefulWidget {
  final List<Lead> leads;
  final FirestoreService svc;

  const LeadsScreen({super.key, required this.leads, required this.svc});

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
      final matchQ = q.isEmpty ||
          l.nameprospecto.toLowerCase().contains(q) ||
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
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Oportunidades',
                      style: TextStyle(fontSize: 12, color: _C.textGrey)),
                  Text('Leads',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _C.textDark)),
                ]),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeadForm(firestoreService: widget.svc),
                    ),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _C.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _searchBar(
                  'Lead, empresa, estado...', (v) => setState(() => _query = v)),
            ),
            const SizedBox(height: 12),
            _filterTabs(
                _tabs, _filtroTab, (t) => setState(() => _filtroTab = t)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('${list.length} leads',
                  style: const TextStyle(fontSize: 13, color: _C.textGrey)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? _emptyState('No hay leads${_filtroTab != "Todos" ? " en estado \"$_filtroTab\"" : " registrados"}')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) =>
                          _leadCard(ctx, list[i]),
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

    return Dismissible(
      key: Key(l.id ?? l.nameprospecto),
      background: _swipeBg(
          color: _C.blue,
          icon: Icons.edit_outlined,
          label: 'Editar',
          alignment: Alignment.centerLeft),
      secondaryBackground: _swipeBg(
          color: _C.red,
          icon: Icons.delete_outline_rounded,
          label: 'Eliminar',
          alignment: Alignment.centerRight),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  LeadForm(lead: l, firestoreService: widget.svc),
            ),
          );
          return false;
        } else {
          return await _confirmarEliminacion(
              context, 'lead', l.nameprospecto);
        }
      },
      onDismissed: (dir) {
        if (dir == DismissDirection.endToStart && l.id != null) {
          widget.svc.eliminarLead(l.id!);
        }
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BitacoraScreen(lead: l, svc: widget.svc),
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
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(l.nameprospecto,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark)),
                const SizedBox(height: 2),
                Text(l.infoprospecto.isEmpty
                    ? l.nameprospecto
                    : l.infoprospecto,
                    style: const TextStyle(fontSize: 12, color: _C.textGrey)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 11, color: _C.textGrey),
                  const SizedBox(width: 4),
                  Text(l.fechaFormateada,
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
                  onTap: () =>
                      _enviarCorreo(l.correo, nombre: l.nameprospecto),
                  child: _iconAction(Icons.mail_outline_rounded, _C.blue),
                ),
              ]),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─── Bitácora tab ─────────────────────────────────────────────────────────────
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
                child: Text(
                  'Entra a un Lead para ver y\nagregar entradas de bitácora.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _C.textGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Perfil ───────────────────────────────────────────────────────────────────
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nombre = user?.displayName ?? 'Usuario';
    final email = user?.email ?? '';
    final initials = _initials(nombre);

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
                    child: Center(
                      child: Text(initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(nombre,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _C.textDark)),
                  const Text('Vendedor',
                      style: TextStyle(fontSize: 13, color: _C.textGrey)),
                ]),
              ),
              const SizedBox(height: 32),
              _profileItem(Icons.mail_outline_rounded, email),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await SessionManager.clearSession();
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginPage()),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
class _MiFAB extends StatelessWidget {
  final FirestoreService svc;
  const _MiFAB({required this.svc});

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: _C.blue,
      foregroundColor: Colors.white,
      spaceBetweenChildren: 8,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.bar_chart_rounded),
          label: 'Agregar Lead',
          backgroundColor: _C.blue,
          foregroundColor: Colors.white,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => LeadForm(firestoreService: svc)),
          ),
        ),
        SpeedDialChild(
          child: const Icon(Icons.person_add_outlined),
          label: 'Agregar Prospecto',
          backgroundColor: _C.blue,
          foregroundColor: Colors.white,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProspectoForm(firestoreService: svc)),
          ),
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
        prefixIcon:
            const Icon(Icons.search, color: _C.textGrey, size: 20),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? _C.blue : _C.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? _C.blue : _C.divider, width: 1.5),
              ),
              child: Text(tabs[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? Colors.white : _C.textMedium,
                  )),
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
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
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

Widget _emptyState(String msg) => Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.inbox_outlined, size: 48, color: _C.textGrey),
        const SizedBox(height: 12),
        Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _C.textGrey, fontSize: 15)),
      ]),
    );

Widget _swipeBg({
  required Color color,
  required IconData icon,
  required String label,
  required Alignment alignment,
}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );

Future<bool> _confirmarEliminacion(
    BuildContext context, String tipo, String nombre) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Eliminar $tipo'),
          content: Text('¿Eliminar "$nombre"? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      ) ??
      false;
}

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

Future<void> _llamar(String telefono) async {
  if (telefono.isEmpty) return;
  final uri = Uri(scheme: 'tel', path: telefono);
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

Future<void> _enviarCorreo(String email, {String? nombre}) async {
  if (email.isEmpty) return;
  final uri = Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: {
      'subject':
          'Seguimiento RapiLead${nombre != null ? " - $nombre" : ""}',
      'body': 'Hola${nombre != null ? " $nombre" : ""},\n\n',
    },
  );
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}
