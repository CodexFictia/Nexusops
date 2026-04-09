import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/models.dart';
import '../core/providers.dart';
import '../core/mock_data.dart';
import '../widgets/shared_widgets.dart';
import 'app_shell.dart';
import 'troubleshoot_screen.dart';

class ExecutiveShell extends StatelessWidget {
  const ExecutiveShell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final user = auth.currentUser!;
    final myOpen = app.myIncidents(user.id).length;
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
        ShellItem(
          label: 'Extended Hrs',
          icon: Icons.schedule_outlined,
          activeIcon: Icons.schedule,
          page: const _ExecExtendedPage(),
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
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final open = app.openIncidents;
    final resolved = app.resolvedIncidents;

    return Column(
      children: [
        // Header with urgency banner
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
                          '${open.length} open · ${app.criticalCount} critical',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Quick stats
                  _QuickStatChip(
                      label: 'Critical',
                      count: app.criticalCount,
                      color: AppColors.error),
                  const SizedBox(width: 8),
                  _QuickStatChip(
                      label: 'Open',
                      count: open.length,
                      color: AppColors.warning),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabs,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                tabs: [
                  Tab(text: 'Open (${open.length})'),
                  Tab(text: 'Resolved (${resolved.length})'),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _OpenIncidentsList(incidents: open),
              _ResolvedIncidentsList(incidents: resolved),
            ],
          ),
        ),
      ],
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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
      padding: const EdgeInsets.all(20),
      itemCount: incidents.length,
      itemBuilder: (ctx, i) {
        final incident = incidents[i];
        return IncidentCard(
          incident: incident,
          onResolve: () async {
            final resolution = await showResolveDialog(ctx, incident);
            if (resolution != null && ctx.mounted) {
              ctx.read<AppProvider>().resolveIncident(incident.id, resolution);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Incident resolved successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          onTroubleshoot: () => Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) =>
                  TroubleshootScreen(preselectedDeviceId: incident.deviceId),
            ),
          ),
        );
      },
    );
  }
}

class _ResolvedIncidentsList extends StatelessWidget {
  final List<Incident> incidents;

  const _ResolvedIncidentsList({required this.incidents});

  @override
  Widget build(BuildContext context) {
    if (incidents.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'No resolved incidents',
        subtitle: 'Resolved incidents will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: incidents.length,
      itemBuilder: (ctx, i) {
        final incident = incidents[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check,
                  color: AppColors.success, size: 18),
            ),
            title: Text(
              '${incident.clientName} — ${incident.floor}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              incident.resolution ?? 'No resolution notes',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              incident.ageLabel,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        );
      },
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

    final onlineCount = devices.where((d) => d.status != DeviceStatus.offline).length;
    final offlineCount = devices.length - onlineCount;

    return PageWrapper(
      title: 'Floor Control',
      subtitle: 'Manage device power states and schedules',
      actions: [
        // Pause All button
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
          // Stats
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total Devices',
                  value: '${devices.length}',
                  subtitle: '${_floors.length - 1} floors · DLF Tower A',
                  accentColor: AppColors.info,
                  icon: Icons.devices,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Online',
                  value: '$onlineCount/${devices.length}',
                  subtitle: '${((onlineCount / devices.length) * 100).toStringAsFixed(0)}% operational',
                  accentColor: AppColors.success,
                  icon: Icons.wifi,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Offline',
                  value: '$offlineCount',
                  subtitle: offlineCount > 0 ? 'Needs attention' : 'All connected',
                  accentColor: offlineCount > 0 ? AppColors.error : AppColors.success,
                  valueColor: offlineCount > 0 ? AppColors.error : null,
                  icon: Icons.wifi_off,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Floor filter
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
          // Device list
          ...devices.map((device) => DeviceTile(
                device: device,
                onToggle: () => context.read<AppProvider>().toggleDevice(device.id),
                onTroubleshoot: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TroubleshootScreen(
                        preselectedDeviceId: device.id),
                  ),
                ),
              )),
          // Schedule reference
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
          'Use this for Holiday/maintenance periods. '
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
                  content: Text('All services paused. Tap Resume All to reactivate.'),
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
              // Header
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
                                color: AppColors.textSecondary))),
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
                final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
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
                                        : AppColors.primary.withOpacity(0.15))
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
                                  fontWeight:
                                      isToday ? FontWeight.w700 : FontWeight.w400,
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
    final ongoing = app.bookings
        .where((b) => b.status == BookingStatus.ongoing)
        .toList();
    final bookings = app.bookings;

    return PageWrapper(
      title: 'Extended Hours',
      subtitle: 'Active extended service sessions',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showBookDialog(context),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New Booking'),
        ),
      ],
      child: Column(
        children: [
          // Stats
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Active Now',
                  value: '${ongoing.length}',
                  subtitle: 'clients on extended service',
                  accentColor: AppColors.success,
                  valueColor: ongoing.isNotEmpty ? AppColors.success : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Total This Month',
                  value: '${bookings.length}',
                  subtitle: 'extended hour sessions',
                  accentColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Avg Duration',
                  value: '5.8hrs',
                  subtitle: 'across all bookings',
                  accentColor: AppColors.info,
                ),
              ),
            ],
          ),
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
      builder: (ctx) => AlertDialog(
        title: const Text('Book Extended Hours'),
        content: const SizedBox(
          width: 400,
          child: Text(
            'Select floor and client to book extended service hours.\n\n'
            'This would open the floor/client selection form in a real implementation.',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

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
          color: isActive ? AppColors.success.withOpacity(0.3) : AppColors.border,
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
              color: booking.billable ? AppColors.successBg : AppColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: booking.billable
                      ? AppColors.success.withOpacity(0.3)
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(10)),
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
                    ? const Border(bottom: BorderSide(color: AppColors.border))
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
