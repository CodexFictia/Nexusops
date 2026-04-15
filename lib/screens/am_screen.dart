import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';
import '../core/models.dart';
import '../core/providers.dart';
import '../core/mock_data.dart';
import '../widgets/shared_widgets.dart';
import 'app_shell.dart';
import 'troubleshoot_screen.dart';

class AccountManagerShell extends StatelessWidget {
  const AccountManagerShell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final user = auth.currentUser!;

    return AppShell(
      user: user,
      items: [
        ShellItem(
          label: 'Overview',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          page: const _AMOverviewPage(),
        ),
        ShellItem(
          label: 'Incidents',
          icon: Icons.warning_amber_outlined,
          activeIcon: Icons.warning_amber,
          badgeCount: app.openCount,
          page: const _AMIncidentsPage(),
        ),
        ShellItem(
          label: 'Team',
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          page: const _AMTeamPage(),
        ),
        ShellItem(
          label: 'Analytics',
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart,
          page: const _AMAnalyticsPage(),
        ),
      ],
    );
  }
}

// ─── Overview Page ────────────────────────────────────────────────────────────

class _AMOverviewPage extends StatelessWidget {
  const _AMOverviewPage();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final statuses = mockExecutiveStatuses;

    final totalResolved =
        statuses.fold(0, (s, e) => s + e.resolvedToday);

    return PageWrapper(
      title: 'Operations Overview',
      subtitle: 'DLF Commercial Tower A · ${_timeNow()}',
      child: Column(
        children: [
          // ── Operations Pulse ──────────────────────────────────────────
          _OpsPulseCard(app: app, totalResolved: totalResolved),
          const SizedBox(height: 20),
          // Team status
          SectionHeader(
            title: 'Field Team Status',
            subtitle: '${statuses.length} executives active',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ),
          LayoutBuilder(builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            if (isMobile) {
              return Column(
                children: statuses
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ExecutiveCard(status: s),
                        ))
                    .toList(),
              );
            }
            return Row(
              children: statuses
                  .map((s) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _ExecutiveCard(status: s),
                        ),
                      ))
                  .toList(),
            );
          }),
          const SizedBox(height: 20),
          // Critical incidents
          SectionHeader(
            title: 'Critical & High Priority',
            subtitle: 'Requires immediate action',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${app.criticalCount} critical',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Builder(builder: (context) {
            final urgent = app.openIncidents
                .where((i) =>
                    i.priority == IncidentPriority.critical ||
                    i.priority == IncidentPriority.high)
                .take(4)
                .toList();
            if (urgent.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.success, size: 24),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Clear',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'No critical or high priority incidents active',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: urgent
                  .map((incident) => IncidentCard(
                        incident: incident,
                        showActions: true,
                        onAssign: () =>
                            _showAssignDialog(context, incident),
                        onResolve: () async {
                          final res =
                              await showResolveDialog(context, incident);
                          if (res != null && context.mounted) {
                            context
                                .read<AppProvider>()
                                .resolveIncident(incident.id, res);
                          }
                        },
                        onTroubleshoot: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TroubleshootScreen(
                                preselectedDeviceId: incident.deviceId),
                          ),
                        ),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context, Incident incident) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Incident'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: mockExecutiveStatuses
              .map((s) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.info.withOpacity(0.1),
                      child: Text(s.executive.initials,
                          style: const TextStyle(
                              color: AppColors.info, fontSize: 12)),
                    ),
                    title: Text(s.executive.name),
                    subtitle: Text(
                        s.currentIncident != null
                            ? 'Busy — ${s.location}'
                            : 'Available — ${s.location}',
                        style: TextStyle(
                            color: s.currentIncident != null
                                ? AppColors.warning
                                : AppColors.success,
                            fontSize: 12)),
                    trailing: Text(
                        '${s.resolvedToday} resolved today',
                        style: const TextStyle(fontSize: 11)),
                    onTap: () {
                      context
                          .read<AppProvider>()
                          .assignIncident(incident.id, s.executive.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Assigned to ${s.executive.name}'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][now.weekday - 1]}, Apr ${now.day} · ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} PM';
  }
}

class _ExecutiveCard extends StatelessWidget {
  final ExecutiveStatus status;

  const _ExecutiveCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final isBusy = status.currentIncident != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBusy ? AppColors.warning.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.info.withOpacity(0.1),
                child: Text(
                  status.executive.initials,
                  style: const TextStyle(
                      color: AppColors.info, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.executive.name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        StatusDot(
                          color: isBusy ? AppColors.warning : AppColors.success,
                          pulse: isBusy,
                          size: 6,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isBusy ? 'On Task' : 'Available',
                          style: TextStyle(
                            fontSize: 11,
                            color: isBusy
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                status.location,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          if (status.currentIncident != null) ...[
            const SizedBox(height: 6),
            Text(
              status.currentIncident!.clientName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${status.resolvedToday} resolved today',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+${status.resolvedToday}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Incidents Page ───────────────────────────────────────────────────────────

class _AMIncidentsPage extends StatefulWidget {
  const _AMIncidentsPage();

  @override
  State<_AMIncidentsPage> createState() => _AMIncidentsPageState();
}

class _AMIncidentsPageState extends State<_AMIncidentsPage> {
  String _priorityFilter = 'All';
  String _statusFilter = 'Open';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    List<Incident> incidents = app.incidents;

    if (_statusFilter == 'Open') {
      incidents = incidents
          .where((i) =>
              i.status == IncidentStatus.open ||
              i.status == IncidentStatus.inProgress)
          .toList();
    } else {
      incidents = incidents
          .where((i) => i.status == IncidentStatus.resolved)
          .toList();
    }

    if (_priorityFilter != 'All') {
      final p = _priorityFilter.toLowerCase();
      incidents = incidents
          .where((i) => i.priority.name.toLowerCase() == p)
          .toList();
    }

    return PageWrapper(
      title: 'Incident Queue',
      subtitle: '${app.openCount} open · ${app.criticalCount} critical · 79 total this month',
      actions: [
        // Status filter
        _FilterChips(
          options: const ['Open', 'Resolved'],
          selected: _statusFilter,
          onSelect: (v) => setState(() {
            _statusFilter = v;
            _priorityFilter = 'All'; // reset priority when switching status
          }),
        ),
        const SizedBox(width: 12),
        _FilterChips(
          options: const ['All', 'Critical', 'High', 'Medium'],
          selected: _priorityFilter,
          onSelect: (v) => setState(() => _priorityFilter = v),
        ),
      ],
      child: incidents.isEmpty
          ? EmptyState(
              icon: _statusFilter == 'Resolved'
                  ? Icons.check_circle_outline
                  : Icons.inbox_outlined,
              title: _statusFilter == 'Resolved'
                  ? 'No resolved incidents'
                  : 'No open incidents',
              subtitle: _priorityFilter != 'All'
                  ? 'No $_priorityFilter priority ${_statusFilter.toLowerCase()} incidents'
                  : _statusFilter == 'Resolved'
                      ? 'Resolved incidents will appear here'
                      : 'All incidents have been resolved — great work!',
            )
          : Column(
              children: incidents
                  .map((i) {
                    final isResolved =
                        i.status == IncidentStatus.resolved;
                    return IncidentCard(
                      incident: i,
                      showActions: !isResolved,
                      onResolve: isResolved
                          ? null
                          : () async {
                              final res =
                                  await showResolveDialog(context, i);
                              if (res != null && context.mounted) {
                                context
                                    .read<AppProvider>()
                                    .resolveIncident(i.id, res);
                              }
                            },
                      onAssign: isResolved ? null : () {},
                      onTroubleshoot: isResolved
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TroubleshootScreen(
                                      preselectedDeviceId: i.deviceId),
                                ),
                              ),
                    );
                  })
                  .toList(),
            ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterChips(
      {required this.options,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options
          .map((o) => GestureDetector(
                onTap: () => onSelect(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected == o
                        ? AppColors.textPrimary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected == o
                          ? AppColors.textPrimary
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    o,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected == o
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ─── Team Page ────────────────────────────────────────────────────────────────

class _AMTeamPage extends StatelessWidget {
  const _AMTeamPage();

  @override
  Widget build(BuildContext context) {
    final statuses = mockExecutiveStatuses;
    final totalResolved = statuses.fold(0, (s, e) => s + e.resolvedToday);

    return PageWrapper(
      title: 'Field Team',
      subtitle: '${statuses.length} executives on shift',
      child: Column(
        children: [
          // ── Team Summary Strip ────────────────────────────────────
          _TeamSummaryStrip(statuses: statuses, totalResolved: totalResolved),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Executive Status Board'),
          ...statuses.map((s) => _TeamMemberCard(status: s)),
          const SizedBox(height: 20),
          const SectionHeader(
            title: 'Unassigned Incidents',
            subtitle: 'Tap to assign to an executive',
          ),
          ...context
              .watch<AppProvider>()
              .openIncidents
              .where((i) => i.assignedTo == null)
              .take(3)
              .map((i) => IncidentCard(
                    incident: i,
                    onAssign: () {},
                    showActions: true,
                  )),
        ],
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final ExecutiveStatus status;

  const _TeamMemberCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final isBusy = status.currentIncident != null;
    final minAgo =
        DateTime.now().difference(status.lastSeen).inMinutes;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.info.withOpacity(0.1),
                child: Text(
                  status.executive.initials,
                  style: const TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          status.executive.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isBusy
                                ? AppColors.warningBg
                                : AppColors.successBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isBusy ? 'On Task' : 'Available',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isBusy
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last seen: $minAgo min ago · ${status.location}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${status.resolvedToday}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                  const Text(
                    'resolved today',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          if (status.currentIncident != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.work,
                      size: 14, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Working on: ${status.currentIncident!.clientName} — ${status.currentIncident!.floor}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Analytics Page ───────────────────────────────────────────────────────────

class _AMAnalyticsPage extends StatelessWidget {
  const _AMAnalyticsPage();

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'Analytics',
      subtitle: 'April 2026 · DLF Commercial Tower A',
      child: Column(
        children: [
          // ── Analytics Summary Strip ───────────────────────────────
          const _AnalyticsSummaryStrip(),
          const SizedBox(height: 20),
          // Incident trend chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _IncidentTrendChart()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _IncidentBreakdownChart()),
            ],
          ),
          const SizedBox(height: 16),
          // Resolution time by client
          _ResolutionTable(),
        ],
      ),
    );
  }
}

class _IncidentTrendChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = [18, 22, 15, 28, 19, 24, 21, 17, 26, 23, 19, 20];
    final months = [
      'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr'
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Incident Trend — Last 12 Months',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Total incidents per month',
            style:
                TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 35,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        months[v.toInt()],
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(
                  show: true,
                  horizontalInterval: 10,
                  drawVerticalLine: false,
                ),
                barGroups: data
                    .asMap()
                    .entries
                    .map((e) => BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.toDouble(),
                              color: e.key == data.length - 1
                                  ? AppColors.primary
                                  : AppColors.info.withOpacity(0.5),
                              width: 18,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentBreakdownChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'By Type',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'April 2026',
            style:
                TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: 43,
                    title: '43%',
                    color: AppColors.error,
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: 28,
                    title: '28%',
                    color: AppColors.warning,
                    radius: 55,
                    titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: 18,
                    title: '18%',
                    color: AppColors.info,
                    radius: 50,
                    titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: 11,
                    title: '11%',
                    color: AppColors.success,
                    radius: 45,
                    titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ],
                centerSpaceRadius: 0,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Legend(color: AppColors.error, label: 'Unauthorized Power'),
          _Legend(color: AppColors.warning, label: 'Schedule Mismatch'),
          _Legend(color: AppColors.info, label: 'Meter Anomaly'),
          _Legend(color: AppColors.success, label: 'Access Control'),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ResolutionTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = [
      ('Hollister Global Business', 7, AppColors.error),
      ('MAAP Marketing LLP', 5, AppColors.warning),
      ('CAP ALPHA Investment', 4, AppColors.warning),
      ('Hexagon Capability Center', 3, AppColors.info),
      ('FNZ Technology', 1, AppColors.success),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('CLIENT',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary))),
                Expanded(
                    child: Text('OPEN INCIDENTS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary))),
                Expanded(
                    flex: 2,
                    child: Text('RESOLUTION TIME',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary))),
              ],
            ),
          ),
          ...data.map((d) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text(d.$1,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500))),
                    Expanded(
                      child: Text(
                        '${d.$2}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: d.$3),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: d.$2 / 10.0,
                                minHeight: 8,
                                backgroundColor: d.$3.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation(d.$3),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${d.$2 * 0.8 + 0.5}h avg',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Operations Pulse Card ────────────────────────────────────────────────────

class _OpsPulseCard extends StatelessWidget {
  final AppProvider app;
  final int totalResolved;

  const _OpsPulseCard({required this.app, required this.totalResolved});

  @override
  Widget build(BuildContext context) {
    final sla = app.slaCompliancePercent;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.07),
            AppColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusDot(
                  color: AppColors.error, pulse: true, size: 8),
              const SizedBox(width: 8),
              const Text(
                'Operations Pulse',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PulseBadge(
                icon: Icons.warning_amber_rounded,
                value: '${app.openCount}',
                label: 'Open',
                color: app.openCount > 5
                    ? AppColors.error
                    : AppColors.warning,
              ),
              if (app.criticalCount > 0)
                _PulseBadge(
                  icon: Icons.priority_high_rounded,
                  value: '${app.criticalCount}',
                  label: 'Critical',
                  color: AppColors.error,
                ),
              _PulseBadge(
                icon: Icons.check_circle_outline,
                value: '$totalResolved',
                label: 'Resolved Today',
                color: AppColors.success,
              ),
              _PulseBadge(
                icon: Icons.timer_outlined,
                value: '${app.avgResolutionHours.toStringAsFixed(1)}h',
                label: 'Avg Resolution',
                color: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'SLA Compliance',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '${sla.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color:
                      sla >= 90 ? AppColors.success : AppColors.warning,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '· target 95%',
                style: TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: sla / 100,
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(
                  sla >= 90 ? AppColors.success : AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _PulseBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.w800, color: color, fontSize: 15),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── Team Summary Strip ───────────────────────────────────────────────────────

class _TeamSummaryStrip extends StatelessWidget {
  final List<ExecutiveStatus> statuses;
  final int totalResolved;

  const _TeamSummaryStrip(
      {required this.statuses, required this.totalResolved});

  @override
  Widget build(BuildContext context) {
    final avg = totalResolved / (statuses.isEmpty ? 1 : statuses.length);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StripStat(
              value: '${statuses.length}',
              label: 'On Shift',
              color: AppColors.success),
          _StripDivider(),
          _StripStat(
              value: '$totalResolved',
              label: 'Resolved Today',
              color: AppColors.info),
          _StripDivider(),
          _StripStat(
              value: avg.toStringAsFixed(1),
              label: 'Avg Per Exec',
              color: AppColors.primary),
        ],
      ),
    );
  }
}

class _StripStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StripStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StripDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 36, color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 8));
}

// ─── Analytics Summary Strip ──────────────────────────────────────────────────

class _AnalyticsSummaryStrip extends StatelessWidget {
  const _AnalyticsSummaryStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        if (isMobile) {
          return Column(
            children: [
              Row(children: [
                Expanded(
                    child: _AnalyticsBit(
                        value: '79',
                        label: 'This Month',
                        badge: '+12%',
                        color: AppColors.warning)),
                Expanded(
                    child: _AnalyticsBit(
                        value: '2.3h',
                        label: 'Avg Resolution',
                        badge: '✓ 4h target',
                        color: AppColors.success)),
              ]),
              Divider(height: 1, color: AppColors.border),
              Row(children: [
                Expanded(
                    child: _AnalyticsBit(
                        value: '34',
                        label: 'After-Hours',
                        badge: '43% of total',
                        color: AppColors.error)),
                Expanded(
                    child: _AnalyticsBit(
                        value: '16',
                        label: 'Ext. Booked',
                        badge: '5.8h avg',
                        color: AppColors.info)),
              ]),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
                child: _AnalyticsBit(
                    value: '79',
                    label: 'This Month',
                    badge: '+12%',
                    color: AppColors.warning)),
            Container(width: 1, height: 48, color: AppColors.border),
            Expanded(
                child: _AnalyticsBit(
                    value: '2.3h',
                    label: 'Avg Resolution',
                    badge: '✓ 4h target',
                    color: AppColors.success)),
            Container(width: 1, height: 48, color: AppColors.border),
            Expanded(
                child: _AnalyticsBit(
                    value: '34',
                    label: 'After-Hours',
                    badge: '43% of total',
                    color: AppColors.error)),
            Container(width: 1, height: 48, color: AppColors.border),
            Expanded(
                child: _AnalyticsBit(
                    value: '16',
                    label: 'Ext. Booked',
                    badge: '5.8h avg',
                    color: AppColors.info)),
          ],
        );
      }),
    );
  }
}

class _AnalyticsBit extends StatelessWidget {
  final String value;
  final String label;
  final String badge;
  final Color color;

  const _AnalyticsBit({
    required this.value,
    required this.label,
    required this.badge,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(badge,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ],
      ),
    );
  }
}
