import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';
import '../core/models.dart';
import '../core/providers.dart';
import '../core/mock_data.dart';
import '../widgets/shared_widgets.dart';
import 'app_shell.dart';

class CentreHeadShell extends StatelessWidget {
  const CentreHeadShell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final user = auth.currentUser!;

    return AppShell(
      user: user,
      items: [
        ShellItem(
          label: 'Building Health',
          icon: Icons.home_work_outlined,
          activeIcon: Icons.home_work,
          page: const _CHBuildingPage(),
        ),
        ShellItem(
          label: 'Clients',
          icon: Icons.business_outlined,
          activeIcon: Icons.business,
          badgeCount: app.criticalClients.length,
          page: const _CHClientsPage(),
        ),
        ShellItem(
          label: 'Meter Analytics',
          icon: Icons.electric_meter_outlined,
          activeIcon: Icons.electric_meter,
          page: const _CHMeterPage(),
        ),
        ShellItem(
          label: 'Reports',
          icon: Icons.summarize_outlined,
          activeIcon: Icons.summarize,
          page: const _CHReportPage(),
        ),
      ],
    );
  }
}

// ─── Building Health Page ─────────────────────────────────────────────────────

class _CHBuildingPage extends StatelessWidget {
  const _CHBuildingPage();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final healthScore = app.buildingHealthScore;

    return PageWrapper(
      title: 'Building Health',
      subtitle: '${BuildingSummary.name} · ${BuildingSummary.city}',
      actions: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download, size: 16),
          label: const Text('Export Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sidebar,
            foregroundColor: Colors.white,
          ),
        ),
      ],
      child: Column(
        children: [
          // Big health score
          _BuildingHealthCard(score: healthScore),
          const SizedBox(height: 16),
          // KPI row
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total Clients',
                  value: '${BuildingSummary.totalClients}',
                  subtitle: '${app.criticalClients.length} at-risk',
                  accentColor: AppColors.info,
                  icon: Icons.business,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Avg CSAT',
                  value: BuildingSummary.overallCsat.toStringAsFixed(1),
                  subtitle: 'Target: ${BuildingSummary.targetCsat}',
                  accentColor: AppColors.primary,
                  icon: Icons.star,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Open Incidents',
                  value: '${BuildingSummary.openIncidents}',
                  subtitle: '${app.criticalCount} critical',
                  accentColor: AppColors.error,
                  valueColor: BuildingSummary.openIncidents > 10
                      ? AppColors.error
                      : null,
                  icon: Icons.warning_amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Monthly Revenue',
                  value: '₹${(BuildingSummary.monthlyRevenue / 100000).toStringAsFixed(1)}L',
                  subtitle:
                      '₹${(BuildingSummary.revenueAtRisk / 1000).toStringAsFixed(0)}K at risk',
                  accentColor: AppColors.success,
                  icon: Icons.currency_rupee,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Alert: clients needing attention
          if (app.criticalClients.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.priority_high,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clients at Risk',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                        Text(
                          '${app.criticalClients.map((c) => c.name.split(' ').first).join(', ')} '
                          '— low health scores, require relationship outreach',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View Clients',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Floor status grid
          SectionHeader(
            title: 'Floor Overview',
            subtitle: '${BuildingSummary.totalFloors} floors · ${BuildingSummary.totalDevices} devices',
          ),
          _FloorGrid(clients: app.clients),
          const SizedBox(height: 20),
          // CSAT trend
          _CSATTrendChart(),
        ],
      ),
    );
  }
}

class _BuildingHealthCard extends StatelessWidget {
  final double score;

  const _BuildingHealthCard({required this.score});

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String get _label {
    if (score >= 80) return 'Healthy';
    if (score >= 60) return 'Needs Attention';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sidebar, AppColors.sidebarHover],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Score ring
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(_color),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.sidebarText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Building Health Score',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: _color.withOpacity(0.5)),
                      ),
                      child: Text(
                        _label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Composite score based on device uptime, incident resolution rate, CSAT, and schedule adherence.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.sidebarText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _ScorePill(
                        label: 'CSAT',
                        value: BuildingSummary.overallCsat.toStringAsFixed(1),
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    _ScorePill(
                        label: 'Uptime',
                        value: '96%',
                        color: AppColors.success),
                    const SizedBox(width: 8),
                    _ScorePill(
                        label: 'SLA',
                        value: '87%',
                        color: AppColors.info),
                    const SizedBox(width: 8),
                    _ScorePill(
                        label: 'Incidents',
                        value: '20',
                        color: AppColors.error),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScorePill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.sidebarText,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloorGrid extends StatelessWidget {
  final List<Client> clients;

  const _FloorGrid({required this.clients});

  @override
  Widget build(BuildContext context) {
    final floors = ['Ground Floor', '1st Floor', '2nd Floor', '3rd Floor'];
    return Column(
      children: floors.map((floor) {
        final floorClients = clients.where((c) => c.floor == floor).toList();
        if (floorClients.isEmpty) return const SizedBox.shrink();
        final avgHealth = floorClients.isEmpty
            ? 100.0
            : floorClients.fold(0.0, (s, c) => s + c.healthScore) /
                floorClients.length;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Row(
                  children: [
                    Text(
                      floor,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${floorClients.length} clients',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      'Avg health: ${avgHealth.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: avgHealth >= 80
                            ? AppColors.success
                            : avgHealth >= 60
                                ? AppColors.warning
                                : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: floorClients
                      .map((c) => _ClientChip(client: c))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ClientChip extends StatelessWidget {
  final Client client;

  const _ClientChip({required this.client});

  Color get _healthColor {
    if (client.healthScore >= 80) return AppColors.success;
    if (client.healthScore >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          '${client.name}\nHealth: ${client.healthScore.toStringAsFixed(0)}%\nCSAT: ${client.csatScore}\nOpen incidents: ${client.openIncidents}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _healthColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _healthColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: _healthColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              client.name.split(' ').take(2).join(' '),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500),
            ),
            if (client.openIncidents > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${client.openIncidents}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CSATTrendChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spots = [
      const FlSpot(0, 3.8),
      const FlSpot(1, 3.9),
      const FlSpot(2, 3.7),
      const FlSpot(3, 4.0),
      const FlSpot(4, 3.9),
      const FlSpot(5, 4.1),
      const FlSpot(6, 4.0),
      const FlSpot(7, 4.2),
      const FlSpot(8, 4.1),
      const FlSpot(9, 4.3),
      const FlSpot(10, 4.2),
      const FlSpot(11, 4.2),
    ];
    final months = [
      'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct',
      'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr'
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
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CSAT Score Trend',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Target: 4.8 · Current: 4.2 · Gap: -0.6 pts',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+50% CSAT target',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 3.0,
                maxY: 5.0,
                lineTouchData: const LineTouchData(enabled: true),
                titlesData: FlTitlesData(
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
                        v.toStringAsFixed(1),
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
                  horizontalInterval: 0.5,
                  drawVerticalLine: false,
                ),
                lineBarsData: [
                  // Actual
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.info,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.info.withOpacity(0.08),
                    ),
                  ),
                  // Target line
                  LineChartBarData(
                    spots: List.generate(12,
                        (i) => FlSpot(i.toDouble(), 4.8)),
                    isCurved: false,
                    color: AppColors.primary.withOpacity(0.6),
                    barWidth: 1.5,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Legend(color: AppColors.info, label: 'Actual CSAT'),
              const SizedBox(width: 16),
              _Legend(color: AppColors.primary, label: 'Target (4.8)'),
            ],
          ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 16,
            height: 3,
            color: color),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Clients Page ─────────────────────────────────────────────────────────────

class _CHClientsPage extends StatefulWidget {
  const _CHClientsPage();

  @override
  State<_CHClientsPage> createState() => _CHClientsPageState();
}

class _CHClientsPageState extends State<_CHClientsPage> {
  String _sort = 'Health';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    List<Client> clients = List.from(app.clients);

    switch (_sort) {
      case 'Health':
        clients.sort((a, b) => a.healthScore.compareTo(b.healthScore));
        break;
      case 'CSAT':
        clients.sort((a, b) => a.csatScore.compareTo(b.csatScore));
        break;
      case 'Incidents':
        clients.sort((a, b) => b.openIncidents.compareTo(a.openIncidents));
        break;
      case 'Contract':
        clients.sort((a, b) => a.contractEnd.compareTo(b.contractEnd));
        break;
    }

    return PageWrapper(
      title: 'Client Overview',
      subtitle: '${clients.length} clients · ${app.criticalClients.length} need attention',
      actions: [
        const Text('Sort by: ',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(width: 4),
        DropdownButton<String>(
          value: _sort,
          underline: const SizedBox(),
          items: ['Health', 'CSAT', 'Incidents', 'Contract']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _sort = v!),
        ),
      ],
      child: Column(
        children: clients.map((c) => _ClientCard(client: c)).toList(),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Client client;

  const _ClientCard({required this.client});

  Color get _healthColor {
    if (client.healthScore >= 80) return AppColors.success;
    if (client.healthScore >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final daysToRenewal =
        client.contractEnd.difference(DateTime.now()).inDays;
    final renewalAlert = daysToRenewal <= 90;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: client.healthScore < 60
              ? AppColors.error.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _healthColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      client.name.substring(0, 2).toUpperCase(),
                      style: TextStyle(
                        color: _healthColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${client.floor} · ${client.deviceCount} devices · ${client.contactName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // CSAT
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          client.csatScore.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'CSAT',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Health bar
            Row(
              children: [
                const Text(
                  'Health',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(child: HealthBar(score: client.healthScore)),
                const SizedBox(width: 8),
                Text(
                  '${client.healthScore.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _healthColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Open incidents
                _InfoPill(
                  icon: Icons.warning_amber,
                  label: '${client.openIncidents} open incidents',
                  color: client.openIncidents > 0
                      ? AppColors.error
                      : AppColors.success,
                ),
                const SizedBox(width: 8),
                // Contract renewal
                _InfoPill(
                  icon: Icons.calendar_today,
                  label: renewalAlert
                      ? 'Renews in $daysToRenewal days'
                      : 'Contract until ${_formatDate(client.contractEnd)}',
                  color: renewalAlert ? AppColors.warning : AppColors.textSecondary,
                ),
                const Spacer(),
                // CTA
                if (client.openIncidents > 0)
                  TextButton.icon(
                    onPressed: () => _showClientDialog(context, client),
                    icon: const Icon(Icons.call, size: 14),
                    label: const Text('Contact'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.info,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            // Issues
            if (client.issues.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        client.issues.join(' · '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showClientDialog(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(client.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact: ${client.contactName}'),
            Text('Email: ${client.contactEmail}'),
            const SizedBox(height: 10),
            Text('Open incidents: ${client.openIncidents}',
                style: const TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
            Text('Health score: ${client.healthScore}%'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Send Update'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ─── Meter Analytics Page ─────────────────────────────────────────────────────

class _CHMeterPage extends StatefulWidget {
  const _CHMeterPage();

  @override
  State<_CHMeterPage> createState() => _CHMeterPageState();
}

class _CHMeterPageState extends State<_CHMeterPage> {
  int _selectedMeter = 0;

  @override
  Widget build(BuildContext context) {
    final meters = mockMeters;
    final meter = meters[_selectedMeter];
    final totalAnomalies =
        meters.fold(0, (s, m) => s + m.anomalyCount);

    return PageWrapper(
      title: 'Meter Analytics',
      subtitle: 'Hourly consumption · Anomaly detection · Auto-raised tickets',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total Meters',
                  value: '${BuildingSummary.totalDevices}',
                  subtitle:
                      '${BuildingSummary.totalFloors} floors · DLF Tower A',
                  accentColor: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Anomalies Today',
                  value: '26',
                  subtitle: 'Across ${meters.length} meters shown',
                  accentColor: AppColors.error,
                  valueColor: AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Tickets Auto-Raised',
                  value: '0',
                  subtitle: 'All open · 0 resolved',
                  accentColor: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Meter selector tabs
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: meters.asMap().entries.map((e) {
                final isSelected = e.key == _selectedMeter;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedMeter = e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            e.value.meterName.split(' ').take(3).join(' '),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.black
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (e.value.anomalyCount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.black.withOpacity(0.2)
                                    : AppColors.errorBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${e.value.anomalyCount} anomaly',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.black
                                      : AppColors.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Chart
          _MeterChart(meter: meter),
        ],
      ),
    );
  }
}

class _MeterChart extends StatelessWidget {
  final MeterReading meter;

  const _MeterChart({required this.meter});

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
          Row(
            children: [
              StatusDot(
                color: meter.anomalyCount > 0
                    ? AppColors.error
                    : AppColors.success,
                size: 8,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meter.meterName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${meter.totalKwh.toStringAsFixed(0)} kWh today',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
          if (meter.anomalyCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${meter.anomalyCount} consumption spike(s) detected',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.error),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        if (v.toInt() % 6 != 0) return const SizedBox();
                        final h = v.toInt();
                        return Text(
                          h == 0 ? '12 AM' : h < 12 ? '$h AM' : h == 12 ? '12 PM' : '${h - 12} PM',
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        v >= 1000
                            ? '${(v / 1000).toStringAsFixed(1)}k'
                            : v.toStringAsFixed(0),
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
                  drawVerticalLine: false,
                ),
                barGroups: meter.hourlyKwh
                    .asMap()
                    .entries
                    .map((e) => BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value,
                              color: meter.anomalies[e.key]
                                  ? AppColors.error
                                  : AppColors.info.withOpacity(0.7),
                              width: 14,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3)),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MeterLegend(color: AppColors.info, label: 'Normal'),
              const SizedBox(width: 16),
              _MeterLegend(
                  color: AppColors.error, label: 'Consumption Spike'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeterLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _MeterLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Reports Page ─────────────────────────────────────────────────────────────

class _CHReportPage extends StatelessWidget {
  const _CHReportPage();

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'Monthly Report',
      subtitle: 'April 2026 · Auto-generated summary',
      actions: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download, size: 16),
          label: const Text('Download PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sidebar,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.email, size: 16),
          label: const Text('Email Report'),
        ),
      ],
      child: Column(
        children: [
          _ReportSummaryCard(),
          const SizedBox(height: 16),
          _ReportSection(
            title: 'Service Continuity',
            items: [
              ('Device uptime', '96.2%', AppColors.success),
              ('SLA compliance (4h resolution)', '87%', AppColors.warning),
              ('Zero-downtime incidents', '43 of 79', AppColors.info),
            ],
          ),
          const SizedBox(height: 12),
          _ReportSection(
            title: 'Financial Summary',
            items: [
              ('Monthly recurring revenue', '₹14,85,000', AppColors.success),
              ('Extended hours billing', '₹42,000', AppColors.info),
              ('Revenue at risk (due to incidents)', '₹1,20,000', AppColors.error),
              ('Ops cost savings vs manual', '₹3,20,000', AppColors.success),
            ],
          ),
          const SizedBox(height: 12),
          _ReportSection(
            title: 'Client Health',
            items: [
              ('Clients — Healthy (>80%)', '5', AppColors.success),
              ('Clients — At Risk (60-80%)', '3', AppColors.warning),
              ('Clients — Critical (<60%)', '3', AppColors.error),
              ('Contracts due in 90 days', '2', AppColors.warning),
            ],
          ),
          const SizedBox(height: 12),
          _ReportSection(
            title: 'Key Wins This Month',
            items: [
              ('E R M India — Extended hours utilisation up 23%', '', AppColors.success),
              ('Nomura — Zero incidents all month', '', AppColors.success),
              ('FNZ Technology — CSAT improved to 4.7', '', AppColors.success),
            ],
          ),
          const SizedBox(height: 12),
          _ReportSection(
            title: 'Action Items',
            items: [
              ('Hollister Global — Contact client, health score critical at 48%', '', AppColors.error),
              ('CAP ALPHA — Investigate eWeLink usage causing incidents', '', AppColors.warning),
              ('Hexagon — Schedule firmware update to fix schedule wipe bug', '', AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Executive Summary — April 2026',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'DLF Commercial Tower A handled 79 incidents this month with an average resolution '
            'time of 2.3 hours against a 4-hour SLA target. Building health stands at 75/100 '
            'driven down by 3 critical clients. CSAT improved to 4.2 from 3.8, tracking toward '
            'the 4.8 target (+50% improvement program). Extended hours revenue contributed '
            '₹42,000 in additional billing. Three clients require immediate relationship '
            'intervention to prevent churn.',
            style: TextStyle(
              color: AppColors.sidebarText,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final List<(String, String, Color)> items;

  const _ReportSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          ...items.map((item) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: item.$3, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item.$1,
                          style: const TextStyle(fontSize: 13)),
                    ),
                    if (item.$2.isNotEmpty)
                      Text(
                        item.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: item.$3,
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
