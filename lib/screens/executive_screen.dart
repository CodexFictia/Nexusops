import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/models.dart';
import '../core/providers.dart';
import '../core/mock_data.dart';
import '../widgets/shared_widgets.dart';
import 'app_shell.dart';
import 'troubleshoot_screen.dart';

// ─── Urgency helpers ──────────────────────────────────────────────────────────

int _urgencyScore(Incident i) {
  final d = i.description.toLowerCase();
  if (i.priority == IncidentPriority.critical &&
      (d.contains('offline') || d.contains('lights off'))) return 100;
  if (d.contains('hvac') || d.contains('temperature') || d.contains('ac')) return 90;
  if (d.contains('access control') || d.contains('rfid') || d.contains('security')) return 80;
  if (d.contains('offline')) return 70;
  if (d.contains('lights on') ||
      d.contains('outside schedule') ||
      d.contains('unauthorized power')) return 50;
  if (d.contains('consumption spike') || d.contains('spike')) return 30;
  if (d.contains('meter silence') || d.contains('meter')) return 20;
  return 10;
}

class _IncidentMeta {
  final IconData icon;
  final Color color;
  final String label;
  const _IncidentMeta(this.icon, this.color, this.label);
}

_IncidentMeta _incidentMeta(Incident i) {
  final d = i.description.toLowerCase();
  if (d.contains('offline') && (d.contains('lights') || d.contains('power'))) {
    return _IncidentMeta(Icons.power_off_rounded, AppColors.error, 'Lights OFF');
  }
  if (d.contains('offline')) {
    return _IncidentMeta(Icons.wifi_off_rounded, AppColors.error, 'Offline');
  }
  if (d.contains('hvac') || d.contains('ac') || d.contains('temperature')) {
    return _IncidentMeta(Icons.ac_unit_rounded, AppColors.error, 'HVAC Alert');
  }
  if (d.contains('access control') || d.contains('rfid')) {
    return _IncidentMeta(Icons.lock_open_rounded, AppColors.error, 'Security');
  }
  if (d.contains('lights on') || d.contains('outside schedule') || d.contains('unauthorized power')) {
    return _IncidentMeta(Icons.lightbulb_rounded, AppColors.warning, 'Investigate');
  }
  if (d.contains('spike') || d.contains('consumption')) {
    return _IncidentMeta(Icons.electric_bolt_rounded, AppColors.warning, 'Power Spike');
  }
  if (d.contains('meter')) {
    return _IncidentMeta(Icons.electric_meter, AppColors.info, 'Meter Issue');
  }
  return _IncidentMeta(Icons.warning_amber_rounded, AppColors.warning, 'Warning');
}

// ─── Shell ────────────────────────────────────────────────────────────────────

class ExecutiveShell extends StatelessWidget {
  const ExecutiveShell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final user = auth.currentUser!;
    final allOpen = app.openCount;

    return AppShell(
      user: user,
      items: [
        ShellItem(
          label: 'My Tasks',
          icon: Icons.task_alt_outlined,
          activeIcon: Icons.task_alt,
          badgeCount: allOpen,
          page: _ExecTasksPage(userId: user.id),
        ),
        ShellItem(
          label: 'Floor Map',
          icon: Icons.map_outlined,
          activeIcon: Icons.map,
          page: const _ExecMapPage(),
        ),
        ShellItem(
          label: 'Floor Control',
          icon: Icons.grid_view_outlined,
          activeIcon: Icons.grid_view,
          page: const _ExecFloorPage(),
        ),
        ShellItem(
          label: 'Troubleshoot',
          icon: Icons.terminal_outlined,
          activeIcon: Icons.terminal,
          page: const TroubleshootScreen(),
        ),
      ],
    );
  }
}

// ─── Tasks Page ───────────────────────────────────────────────────────────────

class _ExecTasksPage extends StatefulWidget {
  final String userId;
  const _ExecTasksPage({required this.userId});

  @override
  State<_ExecTasksPage> createState() => _ExecTasksPageState();
}

class _ExecTasksPageState extends State<_ExecTasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final open = [...app.openIncidents]
      ..sort((a, b) => _urgencyScore(b).compareTo(_urgencyScore(a)));
    final critCount =
        open.where((i) => i.priority == IncidentPriority.critical).length;
    final bookings = app.bookings;
    final ongoing =
        bookings.where((b) => b.status == BookingStatus.ongoing).toList();
    final onExtended = _tabs.index == 1;

    return Column(
      children: [
        Container(
          color: AppColors.card,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Tasks',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          onExtended
                              ? '${bookings.length} bookings · ${ongoing.length} active'
                              : '${open.length} open · $critCount critical',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // CTA changes per tab
                  if (onExtended)
                    ElevatedButton.icon(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const _NewBookingDialog(),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Booking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    )
                  else ...[
                    if (critCount > 0)
                      _QuickStatChip(
                          label: 'Critical',
                          count: critCount,
                          color: AppColors.error),
                    const SizedBox(width: 8),
                    _QuickStatChip(
                        label: 'Open',
                        count: open.length,
                        color: AppColors.warning),
                  ],
                ],
              ),
              // Critical banner — only on open tasks tab
              if (!onExtended && critCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.priority_high_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$critCount critical incident${critCount > 1 ? 's' : ''} require immediate action — sorted to top',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Urgency legend — only on open tasks tab
              if (!onExtended) ...[
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _LegendChip(
                          color: AppColors.error,
                          icon: Icons.power_off_rounded,
                          label: 'Lights OFF'),
                      const SizedBox(width: 6),
                      _LegendChip(
                          color: AppColors.error,
                          icon: Icons.wifi_off_rounded,
                          label: 'Offline'),
                      const SizedBox(width: 6),
                      _LegendChip(
                          color: AppColors.warning,
                          icon: Icons.lightbulb_rounded,
                          label: 'Investigate'),
                      const SizedBox(width: 6),
                      _LegendChip(
                          color: AppColors.warning,
                          icon: Icons.electric_bolt_rounded,
                          label: 'Power Spike'),
                      const SizedBox(width: 6),
                      _LegendChip(
                          color: AppColors.info,
                          icon: Icons.electric_meter_rounded,
                          label: 'Meter Issue'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TabBar(
                controller: _tabs,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                tabs: [
                  Tab(text: 'Open Tasks (${open.length})'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Extended Hrs'),
                        if (ongoing.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${ongoing.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _OpenIncidentsList(incidents: open),
              _ExecExtendedContent(bookings: bookings, ongoing: ongoing),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  const _LegendChip(
      {required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _QuickStatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _QuickStatChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _OpenIncidentsList extends StatelessWidget {
  final List<Incident> incidents;
  const _OpenIncidentsList({required this.incidents});

  @override
  Widget build(BuildContext context) {
    if (incidents.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'All Clear!',
        subtitle: 'No open incidents. Well done.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: incidents.length,
      itemBuilder: (ctx, i) {
        final incident = incidents[i];
        return _ExecIncidentCard(incident: incident);
      },
    );
  }
}

// ─── Field-optimised Incident Card ───────────────────────────────────────────

class _ExecIncidentCard extends StatelessWidget {
  final Incident incident;
  const _ExecIncidentCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    final meta = _incidentMeta(incident);
    final isCritical = incident.priority == IncidentPriority.critical;
    final borderColor = isCritical ? AppColors.error : meta.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: isCritical
            ? [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.18),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left urgency bar
              Container(width: 5, color: borderColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon container
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: meta.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(meta.icon, color: meta.color, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Type badge + age
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color:
                                            meta.color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        meta.label,
                                        style: TextStyle(
                                          color: meta.color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      incident.ageLabel,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Company name
                                Text(
                                  incident.clientName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  incident.floor,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Description box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          incident.description,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TroubleshootScreen(
                                      preselectedDeviceId: incident.deviceId),
                                ),
                              ),
                              icon: const Icon(Icons.terminal_rounded, size: 16),
                              label: const Text('Diagnose'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                side:
                                    const BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final resolution =
                                    await showResolveDialog(context, incident);
                                if (resolution != null && context.mounted) {
                                  context
                                      .read<AppProvider>()
                                      .resolveIncident(incident.id, resolution);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Incident resolved'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_circle_rounded,
                                  size: 18),
                              label: const Text(
                                'Mark Resolved',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCritical
                                    ? AppColors.primary
                                    : AppColors.success,
                                foregroundColor:
                                    isCritical ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Floor Map Page ───────────────────────────────────────────────────────────

class _ExecMapPage extends StatefulWidget {
  const _ExecMapPage();

  @override
  State<_ExecMapPage> createState() => _ExecMapPageState();
}

class _ExecMapPageState extends State<_ExecMapPage> {
  String _selectedFloor = 'Ground Floor';

  final _floors = [
    'Ground Floor',
    '1st Floor',
    '2nd Floor',
    '3rd Floor',
  ];

  // Map floor label → mock_data key
  static const _floorKeys = {
    'Ground Floor': 'Ground Floor',
    '1st Floor': '1st Floor',
    '2nd Floor': '2nd Floor',
    '3rd Floor': '3rd Floor',
  };

  String _zoneStatus(FloorZone zone, AppProvider app) {
    final incidents = app.incidents
        .where((i) =>
            i.clientName == zone.clientName &&
            i.status != IncidentStatus.resolved)
        .toList();
    if (incidents.any((i) => i.priority == IncidentPriority.critical)) {
      return 'red';
    }
    if (incidents.any((i) =>
        i.priority == IncidentPriority.high ||
        i.priority == IncidentPriority.medium)) {
      return 'yellow';
    }
    return 'green';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final floorKey = _floorKeys[_selectedFloor] ?? _selectedFloor;
    final rows = floorZoneMap[floorKey] ?? [];

    // Collect incidents for the selected floor
    final floorIncidents = app.incidents
        .where((i) =>
            i.floor == _selectedFloor && i.status != IncidentStatus.resolved)
        .toList()
      ..sort((a, b) => _urgencyScore(b).compareTo(_urgencyScore(a)));

    final redCount =
        rows.expand((r) => r).where((z) => _zoneStatus(z, app) == 'red').length;
    final yellowCount = rows
        .expand((r) => r)
        .where((z) => _zoneStatus(z, app) == 'yellow')
        .length;

    return PageWrapper(
      title: 'Floor Map',
      subtitle: 'Zone status at a glance',
      child: Column(
        children: [
          // Floor selector + stats row
          KpiGrid(cards: [
            StatCard(
              label: 'Issues',
              value: '$redCount',
              subtitle: 'zones need attention',
              accentColor: AppColors.error,
              icon: Icons.error_outline,
              valueColor: redCount > 0 ? AppColors.error : null,
            ),
            StatCard(
              label: 'Warnings',
              value: '$yellowCount',
              subtitle: 'zones to investigate',
              accentColor: AppColors.warning,
              icon: Icons.warning_amber_outlined,
              valueColor: yellowCount > 0 ? AppColors.warning : null,
            ),
            StatCard(
              label: 'Floor',
              value: _selectedFloor.replaceAll(' Floor', '').replaceAll('nd', '').replaceAll('rd', '').replaceAll('st', ''),
              subtitle: 'selected · tap to change',
              accentColor: AppColors.info,
              icon: Icons.layers_outlined,
            ),
          ]),
          const SizedBox(height: 20),

          // Floor selector tabs
          SectionHeader(
            title: 'Select Floor',
            trailing: null,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _floors.map((f) {
                final isSelected = f == _selectedFloor;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFloor = f),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Floor plan container
          Container(
            decoration: BoxDecoration(
              color: AppColors.sidebar,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header bar
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.sidebar.withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.apartment_rounded,
                          color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'DLF Tower A · $_selectedFloor',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Tap zone for details',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Zone rows
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: rows.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No zones on this floor',
                              style: TextStyle(color: Colors.white38),
                            ),
                          ),
                        )
                      : Column(
                          children: rows.map((row) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: row.asMap().entries.map((e) {
                                  final zone = e.value;
                                  final isLast = e.key == row.length - 1;
                                  final status =
                                      _zoneStatus(zone, app);
                                  return Expanded(
                                    flex: zone.flex,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          right: isLast ? 0 : 8),
                                      child: _ZoneCard(
                                        zone: zone,
                                        status: status,
                                        onTap: () => _showZoneDetail(
                                            context, zone, status, app),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                // Legend
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Colors.white12)),
                  ),
                  child: const Row(
                    children: [
                      _MapLegend(
                          color: AppColors.error, label: 'Service disruption'),
                      SizedBox(width: 16),
                      _MapLegend(
                          color: AppColors.warning,
                          label: 'Investigation needed'),
                      SizedBox(width: 16),
                      _MapLegend(
                          color: AppColors.success, label: 'All good'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floor incident summary
          if (floorIncidents.isNotEmpty) ...[
            const SizedBox(height: 20),
            SectionHeader(
              title: 'Active Incidents — $_selectedFloor',
              subtitle: '${floorIncidents.length} unresolved',
            ),
            ...floorIncidents.map(
                (i) => _ExecIncidentCard(incident: i)),
          ] else ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'No active incidents on this floor',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showZoneDetail(
      BuildContext context, FloorZone zone, String status, AppProvider app) {
    final incidents = app.incidents
        .where((i) =>
            i.clientName == zone.clientName &&
            i.status != IncidentStatus.resolved)
        .toList()
      ..sort((a, b) => _urgencyScore(b).compareTo(_urgencyScore(a)));

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    if (status == 'red') {
      statusColor = AppColors.error;
      statusLabel = 'Service disruption';
      statusIcon = Icons.error_rounded;
    } else if (status == 'yellow') {
      statusColor = AppColors.warning;
      statusLabel = 'Needs investigation';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = AppColors.success;
      statusLabel = 'All clear';
      statusIcon = Icons.check_circle_rounded;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.clientName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${zone.zone} · $_selectedFloor · $statusLabel',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            if (incidents.isEmpty)
              const Text(
                'No active incidents for this zone.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ...incidents.map((i) {
                final meta = _incidentMeta(i);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(meta.icon, color: meta.color, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            meta.label,
                            style: TextStyle(
                              color: meta.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(i.ageLabel,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(i.description,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TroubleshootScreen(
                                        preselectedDeviceId: i.deviceId),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.terminal_rounded,
                                  size: 14),
                              label: const Text('Diagnose'),
                              style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                final resolution =
                                    await showResolveDialog(context, i);
                                if (resolution != null && context.mounted) {
                                  context
                                      .read<AppProvider>()
                                      .resolveIncident(i.id, resolution);
                                }
                              },
                              icon: const Icon(Icons.check_rounded, size: 14),
                              label: const Text('Resolve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final FloorZone zone;
  final String status; // 'red' | 'yellow' | 'green'
  final VoidCallback onTap;

  const _ZoneCard(
      {required this.zone, required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color baseColor;
    Color textColor;
    IconData statusIcon;
    if (status == 'red') {
      baseColor = AppColors.error;
      textColor = Colors.white;
      statusIcon = Icons.error_rounded;
    } else if (status == 'yellow') {
      baseColor = AppColors.warning;
      textColor = Colors.black87;
      statusIcon = Icons.warning_amber_rounded;
    } else {
      baseColor = AppColors.success;
      textColor = Colors.white;
      statusIcon = Icons.check_circle_rounded;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 80,
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: baseColor, width: 1.5),
          boxShadow: status == 'red'
              ? [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: textColor, size: 14),
                  const Spacer(),
                  Text(
                    zone.zone,
                    style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                zone.shortName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _MapLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}

// ─── Floor Control Page ───────────────────────────────────────────────────────

class _ExecFloorPage extends StatefulWidget {
  const _ExecFloorPage();

  @override
  State<_ExecFloorPage> createState() => _ExecFloorPageState();
}

class _ExecFloorPageState extends State<_ExecFloorPage> {
  String _selectedFloor = 'All Floors';

  final _floors = [
    'All Floors',
    'Ground Floor',
    '1st Floor',
    '2nd Floor',
    '3rd Floor',
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final devices = _selectedFloor == 'All Floors'
        ? app.devices
        : app.devices.where((d) => d.floor == _selectedFloor).toList();

    final onlineCount =
        devices.where((d) => d.status != DeviceStatus.offline).length;
    final offlineCount = devices.length - onlineCount;

    return PageWrapper(
      title: 'Floor Control',
      subtitle: 'Manage device power states and schedules',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showPauseAllDialog(context),
          icon: const Icon(Icons.pause_circle, size: 16),
          label: const Text('Pause All'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sidebar,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _showResumeAllDialog(context),
          icon: const Icon(Icons.play_circle, size: 16),
          label: const Text('Resume All'),
        ),
      ],
      child: Column(
        children: [
          KpiGrid(cards: [
            StatCard(
              label: 'Total Devices',
              value: '${devices.length}',
              subtitle: '${_floors.length - 1} floors · DLF Tower A',
              accentColor: AppColors.info,
              icon: Icons.devices,
            ),
            StatCard(
              label: 'Online',
              value: '$onlineCount/${devices.length}',
              subtitle: devices.isNotEmpty
                  ? '${((onlineCount / devices.length) * 100).toStringAsFixed(0)}% operational'
                  : '—',
              accentColor: AppColors.success,
              icon: Icons.wifi,
            ),
            StatCard(
              label: 'Offline',
              value: '$offlineCount',
              subtitle: offlineCount > 0
                  ? 'Needs attention'
                  : 'All connected',
              accentColor:
                  offlineCount > 0 ? AppColors.error : AppColors.success,
              valueColor: offlineCount > 0 ? AppColors.error : null,
              icon: Icons.wifi_off,
            ),
          ]),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Devices by Floor',
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFloor,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary),
                items: _floors
                    .map((f) =>
                        DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedFloor = v!),
              ),
            ),
          ),
          ...devices.map((device) => DeviceTile(
                device: device,
                onToggle: () =>
                    context.read<AppProvider>().toggleDevice(device.id),
                onTroubleshoot: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        TroubleshootScreen(preselectedDeviceId: device.id),
                  ),
                ),
              )),
          const SizedBox(height: 20),
          _ScheduleTable(devices: devices.take(3).toList()),
        ],
      ),
    );
  }

  void _showPauseAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pause All Services'),
        content: const Text(
          'This will pause all active Sonoff devices on this floor. '
          'Use this for holiday/maintenance periods. '
          'Scheduled services will not auto-resume.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'All services paused. Tap Resume All to reactivate.'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sidebar,
                foregroundColor: Colors.white),
            child: const Text('Pause All'),
          ),
        ],
      ),
    );
  }

  void _showResumeAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resume All Services'),
        content: const Text(
          'This will resume all paused devices and restore their default schedules.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All services resumed.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Resume All'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTable extends StatelessWidget {
  final List<Device> devices;
  const _ScheduleTable({required this.devices});

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Schedule Reference',
          subtitle: 'Weekly on/off times per device',
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text('Device',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                    ),
                    ...['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                        .map((d) => Expanded(
                              child: Text(d,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary)),
                            )),
                  ],
                ),
              ),
              ...devices.asMap().entries.map((e) {
                final device = e.value;
                final isLast = e.key == devices.length - 1;
                final days = [
                  'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'
                ];
                return Container(
                  decoration: BoxDecoration(
                    border: !isLast
                        ? const Border(
                            bottom: BorderSide(color: AppColors.border))
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            device.name.replaceAll('SONOFF-', ''),
                            style: const TextStyle(
                                fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ),
                        ...days.map((d) {
                          final slot = device.schedule[d] ?? 'OFF';
                          final isOff = slot == 'OFF';
                          final isToday = d ==
                              ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                                  [DateTime.now().weekday - 1];
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 2),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? (isOff
                                        ? AppColors.border
                                        : AppColors.primary
                                            .withValues(alpha: 0.15))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: isToday
                                    ? Border.all(
                                        color: isOff
                                            ? AppColors.border
                                            : AppColors.primary,
                                        width: 1)
                                    : null,
                              ),
                              child: Text(
                                isOff ? 'OFF' : slot.split('-')[0],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isOff
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Extended Hours Page ──────────────────────────────────────────────────────

class _ExecExtendedPage extends StatelessWidget {
  const _ExecExtendedPage();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final ongoing =
        app.bookings.where((b) => b.status == BookingStatus.ongoing).toList();
    final bookings = app.bookings;

    return PageWrapper(
      title: 'Extended Hours',
      subtitle: 'Client service outside contracted schedule',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showBookDialog(context),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New Booking'),
        ),
      ],
      child: Column(
        children: [
          // Explainer box — ALWAYS visible
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.info, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'What are Extended Hours?',
                      style: TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Extended Hours = time a client uses the office OUTSIDE their contracted schedule.\n\n'
                  'Each client has a default schedule (e.g. Mon–Fri, 9AM–6PM). '
                  'A booking MUST be raised for any usage outside those hours.\n\n'
                  'If lights are ON outside schedule with NO booking → that is an UNAUTHORIZED INCIDENT and must be investigated immediately.',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: AppColors.error, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Bookings can ONLY be made for times OUTSIDE the default schedule.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Compact session strip — no stat cards
          _SessionStrip(ongoing: ongoing, bookings: bookings),
          const SizedBox(height: 20),

          if (ongoing.isNotEmpty) ...[
            const SectionHeader(
              title: 'Active Sessions',
              subtitle: 'Currently running extended hours',
            ),
            ...ongoing.map((b) => _BookingCard(booking: b, isActive: true)),
            const SizedBox(height: 20),
          ],

          const SectionHeader(
            title: 'All Bookings',
            subtitle: 'Complete history · Most recent first',
          ),
          _BookingsTable(bookings: bookings),
        ],
      ),
    );
  }

  void _showBookDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _NewBookingDialog(),
    );
  }
}

// ─── Extended Content Tab (embedded in My Tasks) ─────────────────────────────

class _ExecExtendedContent extends StatelessWidget {
  final List<ExtendedHoursBooking> bookings;
  final List<ExtendedHoursBooking> ongoing;

  const _ExecExtendedContent(
      {required this.bookings, required this.ongoing});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.info, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Book for any client usage OUTSIDE their contracted schedule. '
                    'Lights ON without a booking → unauthorized incident.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Session strip
          _SessionStrip(ongoing: ongoing, bookings: bookings),
          const SizedBox(height: 20),
          if (ongoing.isNotEmpty) ...[
            const SectionHeader(
                title: 'Active Sessions',
                subtitle: 'Currently running'),
            ...ongoing.map((b) => _BookingCard(booking: b, isActive: true)),
            const SizedBox(height: 16),
          ],
          const SectionHeader(
              title: 'All Bookings',
              subtitle: 'Complete history · Most recent first'),
          _BookingsTable(bookings: bookings),
        ],
      ),
    );
  }
}

// ─── Session Strip ────────────────────────────────────────────────────────────

class _SessionStrip extends StatelessWidget {
  final List<ExtendedHoursBooking> ongoing;
  final List<ExtendedHoursBooking> bookings;

  const _SessionStrip(
      {required this.ongoing, required this.bookings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          StatusDot(
            color: ongoing.isNotEmpty
                ? AppColors.success
                : AppColors.border,
            pulse: ongoing.isNotEmpty,
            size: 8,
          ),
          const SizedBox(width: 10),
          Text(
            ongoing.isNotEmpty
                ? '${ongoing.length} active'
                : 'No active sessions',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: ongoing.isNotEmpty
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 16, color: AppColors.border),
          const SizedBox(width: 14),
          const Icon(Icons.calendar_today_outlined,
              size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            '${bookings.length} this month',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const Spacer(),
          const Icon(Icons.timer_outlined,
              size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          const Text(
            '5.8h avg',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Booking Card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final ExtendedHoursBooking booking;
  final bool isActive;

  const _BookingCard({required this.booking, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successBg : AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          StatusDot(
            color: isActive ? AppColors.success : AppColors.textSecondary,
            pulse: isActive,
            size: 10,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.clientName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${booking.floor} · ${booking.timeRange} · ${booking.duration}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: booking.source == BookingSource.ops
                  ? AppColors.warningBg
                  : AppColors.infoBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              booking.source == BookingSource.ops ? 'Ops' : 'Client',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: booking.source == BookingSource.ops
                    ? AppColors.warning
                    : AppColors.info,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: booking.billable
                  ? AppColors.successBg
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: booking.billable
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.border),
            ),
            child: Text(
              booking.billable ? 'Billable' : 'Non-bill',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: booking.billable
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingsTable extends StatelessWidget {
  final List<ExtendedHoursBooking> bookings;
  const _BookingsTable({required this.bookings});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _TH('CLIENT')),
                Expanded(flex: 2, child: _TH('FLOOR')),
                Expanded(flex: 2, child: _TH('TIME')),
                Expanded(child: _TH('DURATION')),
                Expanded(child: _TH('SOURCE')),
                Expanded(child: _TH('STATUS')),
              ],
            ),
          ),
          ...bookings.asMap().entries.map((e) {
            final b = e.value;
            final isLast = e.key == bookings.length - 1;
            Color statusColor;
            String statusLabel;
            switch (b.status) {
              case BookingStatus.ongoing:
                statusColor = AppColors.success;
                statusLabel = 'Ongoing';
                break;
              case BookingStatus.completed:
                statusColor = AppColors.textSecondary;
                statusLabel = 'Completed';
                break;
              case BookingStatus.upcoming:
                statusColor = AppColors.info;
                statusLabel = 'Upcoming';
                break;
              case BookingStatus.cancelled:
                statusColor = AppColors.error;
                statusLabel = 'Cancelled';
                break;
            }
            return Container(
              decoration: BoxDecoration(
                border: !isLast
                    ? const Border(
                        bottom: BorderSide(color: AppColors.border))
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(b.clientName,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                        flex: 2,
                        child: Text(b.floor,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary))),
                    Expanded(
                        flex: 2,
                        child: Text(b.timeRange,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary))),
                    Expanded(
                        child: Text(b.duration,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary))),
                    Expanded(
                      child: Text(
                        b.source == BookingSource.ops ? 'Ops' : 'Client',
                        style: TextStyle(
                            fontSize: 12,
                            color: b.source == BookingSource.ops
                                ? AppColors.warning
                                : AppColors.info,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );
}

// ─── New Booking Dialog ───────────────────────────────────────────────────────

class _NewBookingDialog extends StatefulWidget {
  const _NewBookingDialog();

  @override
  State<_NewBookingDialog> createState() => _NewBookingDialogState();
}

class _NewBookingDialogState extends State<_NewBookingDialog> {
  int _step = 0;

  // Step 0
  Client? _selectedClient;

  // Step 1
  String _startTime = '6PM';
  String _endTime = '10PM';

  // Step 2
  String _reason = 'ops'; // 'ops' | 'client'
  bool _billable = false;

  final _startOptions = ['6PM', '7PM', '8PM', '9PM', '10PM', '11PM'];
  final _endOptions = ['8PM', '9PM', '10PM', '11PM', '12AM', '1AM', '2AM'];

  String _calcDuration() {
    final startH = _timeToHour(_startTime);
    final endH = _timeToHour(_endTime);
    final diff = endH > startH ? endH - startH : (24 - startH) + endH;
    return '${diff}h';
  }

  int _timeToHour(String t) {
    final map = {
      '6PM': 18, '7PM': 19, '8PM': 20, '9PM': 21, '10PM': 22,
      '11PM': 23, '12AM': 0, '1AM': 1, '2AM': 2,
    };
    return map[t] ?? 18;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New Extended Hours Booking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Step ${_step + 1} of 3 — ${['Choose Client', 'Floor & Zone', 'Reason & Confirm'][_step]}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            // Step progress
            LinearProgressIndicator(
              value: (_step + 1) / 3,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStep(),
              ),
            ),
            // Bottom actions
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  if (_step > 0)
                    OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  if (_step < 2)
                    ElevatedButton(
                      onPressed: _canContinue()
                          ? () => setState(() => _step++)
                          : null,
                      child: const Text('Continue'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Confirm Booking'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canContinue() {
    if (_step == 0) return _selectedClient != null;
    if (_step == 1) return true;
    return _reason.isNotEmpty;
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildStepClient();
      case 1:
        return _buildStepFloor();
      case 2:
        return _buildStepReason();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepClient() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Client',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...mockClients.map((client) {
          final isSelected = _selectedClient?.id == client.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedClient = client),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${client.floor} · Mon–Fri 9AM–6PM',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStepFloor() {
    final client = _selectedClient!;
    final floorZones = floorZoneMap[client.floor] ?? [];
    final zones = floorZones
        .expand((row) => row)
        .where((z) => z.clientName == client.name)
        .map((z) => z.zone)
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Floor display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.layers_outlined, color: AppColors.info, size: 16),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Floor: ${client.floor}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                  const Text(
                    'Default schedule: Mon–Fri 9AM–6PM',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (zones.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Zone',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: zones
                .map((z) => Chip(
                      label: Text(z),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 20),
        const Text(
          'Start Time',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _startOptions.map((t) {
            final isSelected = _startTime == t;
            return GestureDetector(
              onTap: () => setState(() => _startTime = t),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text(
          'End Time',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _endOptions.map((t) {
            final isSelected = _endTime == t;
            return GestureDetector(
              onTap: () => setState(() => _endTime = t),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepReason() {
    final client = _selectedClient!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client.name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${client.floor} · $_startTime–$_endTime · ${_calcDuration()}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Reason',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        // Ops initiated card
        GestureDetector(
          onTap: () => setState(() {
            _reason = 'ops';
            _billable = false;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _reason == 'ops'
                  ? AppColors.warning.withValues(alpha: 0.08)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _reason == 'ops' ? AppColors.warning : AppColors.border,
                width: _reason == 'ops' ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.support_agent,
                      color: AppColors.warning, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ops Initiated',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'We are enabling this — no client request',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (_reason == 'ops')
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.warning, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Client initiated card
        GestureDetector(
          onTap: () => setState(() {
            _reason = 'client';
            _billable = true;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _reason == 'client'
                  ? AppColors.info.withValues(alpha: 0.08)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _reason == 'client' ? AppColors.info : AppColors.border,
                width: _reason == 'client' ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business,
                      color: AppColors.info, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Client Initiated',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Client requested extended access',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (_reason == 'client')
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.info, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Billable toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Bill to client?',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                value: _billable,
                onChanged: (v) => setState(() => _billable = v),
                activeColor: AppColors.success,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirm() {
    final client = _selectedClient!;
    final booking = ExtendedHoursBooking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clientName: client.name,
      floor: client.floor,
      date: DateTime.now(),
      timeRange: '$_startTime–$_endTime',
      duration: _calcDuration(),
      source: _reason == 'ops' ? BookingSource.ops : BookingSource.client,
      billable: _billable,
      status: BookingStatus.upcoming,
    );
    context.read<AppProvider>().addBooking(booking);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking confirmed for ${client.name}'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
