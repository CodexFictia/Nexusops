import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/models.dart';
import '../core/mock_data.dart';
import 'app_shell.dart';

// ─── Crown Jewel: Troubleshooting Tool ────────────────────────────────────────

class TroubleshootScreen extends StatefulWidget {
  final String? preselectedDeviceId;

  const TroubleshootScreen({super.key, this.preselectedDeviceId});

  @override
  State<TroubleshootScreen> createState() => _TroubleshootScreenState();
}

class _TroubleshootScreenState extends State<TroubleshootScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Device? _selectedDevice;
  bool _isRunning = false;
  bool _isDone = false;
  List<DiagnosticLog> _logs = [];
  String? _aiAnalysis;
  String? _rootCause;
  List<String> _suggestedActions = [];
  String _riskLevel = '';
  Timer? _timer;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    if (widget.preselectedDeviceId != null) {
      try {
        _selectedDevice = mockDevices.firstWhere(
          (d) => d.id == widget.preselectedDeviceId,
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _runDiagnostics() {
    if (_selectedDevice == null || _isRunning) return;
    setState(() {
      _isRunning = true;
      _isDone = false;
      _logs = [];
      _aiAnalysis = null;
      _suggestedActions = [];
    });
    _tabs.animateTo(1);
    _simulateDiagnostics();
  }

  void _simulateDiagnostics() {
    final device = _selectedDevice!;
    final isOffline = device.status == DeviceStatus.offline;
    final isOn = device.status == DeviceStatus.on;
    final onSchedule = device.isOnSchedule;

    final logSequence = [
      (
        ms: 100,
        level: 'INFO',
        msg:
            'Starting diagnostics for device: ${device.name}'
      ),
      (
        ms: 300,
        level: 'INFO',
        msg: 'Checking network connectivity...'
      ),
      (
        ms: 700,
        level: isOffline ? 'ERROR' : 'SUCCESS',
        msg: isOffline
            ? 'Device unreachable — no response on ${device.ipAddress}'
            : 'Device reachable at ${device.ipAddress} · Latency: ${_rand(8, 45)}ms'
      ),
      (
        ms: 1100,
        level: 'INFO',
        msg: 'Checking MAC registration: ${device.macAddress}'
      ),
      (
        ms: 1400,
        level: 'SUCCESS',
        msg: 'MAC registered in Nexus device registry'
      ),
      (
        ms: 1700,
        level: 'INFO',
        msg: 'Querying ASUS-RT-AX88U router logs...'
      ),
      (
        ms: 2100,
        level: 'INFO',
        msg: 'Router connection established. Pulling last 50 events...'
      ),
      (
        ms: 2500,
        level: 'INFO',
        msg:
            'Last seen by router: ${_formatTime(DateTime.now().subtract(const Duration(minutes: 3)))}'
      ),
      (
        ms: 2900,
        level: isOn && !onSchedule ? 'WARN' : 'INFO',
        msg: isOn && !onSchedule
            ? 'POWER_ON command received at ${_formatTime(DateTime.now().subtract(const Duration(hours: 11)))} — outside schedule window'
            : 'Device power state matches schedule'
      ),
      (
        ms: 3200,
        level: 'INFO',
        msg: 'Checking Nexus command registry for authorization...'
      ),
      (
        ms: 3600,
        level: isOn && !onSchedule ? 'ERROR' : 'SUCCESS',
        msg: isOn && !onSchedule
            ? 'UNAUTHORIZED — Command not found in Nexus registry. Possible third-party trigger.'
            : 'Last command authorized by Nexus schedule engine'
      ),
      (
        ms: 4000,
        level: 'INFO',
        msg: 'Scanning floor AP for unregistered devices...'
      ),
      (
        ms: 4400,
        level: 'WARN',
        msg:
            '${_rand(2, 5)} unregistered devices found on ${device.floor} AP segment'
      ),
      (
        ms: 4700,
        level: 'INFO',
        msg: 'Checking eWeLink cloud for out-of-band commands...'
      ),
      (
        ms: 5100,
        level: isOn && !onSchedule ? 'WARN' : 'INFO',
        msg: isOn && !onSchedule
            ? 'eWeLink cloud activity detected for this device ID in last 12h'
            : 'No eWeLink activity detected'
      ),
      (
        ms: 5500,
        level: 'INFO',
        msg: isOffline
            ? 'Testing alternative connection methods...'
            : 'Checking device firmware version...'
      ),
      (
        ms: 5900,
        level: isOffline ? 'ERROR' : 'SUCCESS',
        msg: isOffline
            ? 'Hotspot fallback also unreachable — device may be physically disconnected'
            : 'Firmware v3.6.1 — up to date'
      ),
      (
        ms: 6300,
        level: 'INFO',
        msg: 'Pulling power consumption history from smart meter...'
      ),
      (
        ms: 6700,
        level: 'INFO',
        msg:
            'Consumption reading: ${_rand(45, 280)} kWh in last 6h. Within baseline range.'
      ),
      (
        ms: 7100,
        level: 'INFO',
        msg: 'Running schedule conflict check...'
      ),
      (
        ms: 7400,
        level: onSchedule ? 'SUCCESS' : 'WARN',
        msg: onSchedule
            ? 'No schedule conflicts detected'
            : 'Current time (${_formatTime(DateTime.now())}) outside schedule window. Schedule: ${device.schedule['WED'] ?? 'OFF'}'
      ),
      (
        ms: 7700,
        level: 'INFO',
        msg: 'Generating AI diagnosis...'
      ),
      (
        ms: 8000,
        level: isOffline
            ? 'ERROR'
            : isOn && !onSchedule
                ? 'WARN'
                : 'SUCCESS',
        msg: isOffline
            ? 'DIAGNOSIS: Device Offline — Physical inspection required'
            : isOn && !onSchedule
                ? 'DIAGNOSIS: Unauthorized Power Activation — eWeLink or physical trigger'
                : 'DIAGNOSIS: Device operating normally within schedule'
      ),
    ];

    int delay = 0;
    for (final entry in logSequence) {
      delay += entry.ms;
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;
        setState(() {
          _logs.add(DiagnosticLog(
            timestamp: DateTime.now(),
            level: entry.level,
            message: entry.msg,
          ));
        });
        // Auto-scroll
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }

    // Final: generate AI analysis
    Future.delayed(Duration(milliseconds: delay + 500), () {
      if (!mounted) return;
      _generateAIAnalysis(device);
      setState(() {
        _isRunning = false;
        _isDone = true;
      });
    });
  }

  void _generateAIAnalysis(Device device) {
    final isOffline = device.status == DeviceStatus.offline;
    final isOn = device.status == DeviceStatus.on;
    final onSchedule = device.isOnSchedule;

    if (isOffline) {
      _aiAnalysis = 'Device Offline — Hardware Failure or Disconnection';
      _rootCause =
          'SONOFF device ${device.name} is not responding to network queries. '
          'The device was last seen by the router 3 minutes before this diagnostic. '
          'Power supply interruption or physical disconnection is the most likely cause. '
          'The device is within an active schedule window — this is causing a service disruption for ${device.clientName}.';
      _suggestedActions = [
        'Physically inspect the device at ${device.floor} — check power supply and ethernet/WiFi connection',
        'Check the building circuit breaker for the ${device.floor} segment',
        'If device is unresponsive after power cycle, replace with spare unit from store',
        'Log as a P1 incident and notify ${device.clientName} contact immediately',
        'Update extended hours booking if service disruption exceeds 15 minutes',
      ];
      _riskLevel = 'HIGH — Client service disruption in progress';
    } else if (isOn && !onSchedule) {
      _aiAnalysis = 'Unauthorized Power Activation Detected';
      _rootCause =
          'A POWER_ON command was sent to ${device.name} at 12:00 AM, '
          'well outside the registered schedule window (${device.schedule['WED'] ?? 'not set'} on Wednesdays). '
          'The command was NOT issued by Nexus Ops. eWeLink cloud activity was detected, '
          'suggesting the client\'s staff may have used the eWeLink mobile app. '
          '${_rand(2, 5)} unregistered mobile devices were found on the floor AP, '
          'corroborating unauthorized access.';
      _suggestedActions = [
        'Confirm with ${device.clientName} if staff accessed the office after hours',
        'Request client to disable personal eWeLink accounts linked to this device',
        'If confirmed client activity: create an Extended Hours booking (Ops-initiated) for billing purposes',
        'If unauthorized: revoke eWeLink device sharing via Nexus Admin Panel',
        'Add to after-hours activity log and mark incident accordingly',
        'Consider enabling Nexus-only command mode to block third-party apps',
      ];
      _riskLevel = 'MEDIUM — Billing impact, no safety concern';
    } else {
      _aiAnalysis = 'Device Operating Normally';
      _rootCause =
          '${device.name} is functioning correctly within its scheduled window. '
          'Power state matches the configured schedule. '
          'No unauthorized commands detected in the last 24 hours. '
          'Network connectivity is stable with ${_rand(8, 20)}ms average latency. '
          'Firmware is up to date.';
      _suggestedActions = [
        'No immediate action required',
        'Monitor meter readings for consumption anomalies',
        'Verify schedule alignment if client reports issues',
      ];
      _riskLevel = 'LOW — No action required';
    }

    setState(() {});
  }

  int _rand(int min, int max) => min + Random().nextInt(max - min);

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isFullPage = widget.preselectedDeviceId == null;

    Widget content = Column(
      children: [
        // Header
        Container(
          color: AppColors.card,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!isFullPage)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Troubleshooting Tool',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'AI-assisted device diagnostics · WiFi router log analysis · Fix suggestions',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (_isDone)
                    OutlinedButton.icon(
                      onPressed: _exportLogs,
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Device selector
              _DeviceSelector(
                selectedDevice: _selectedDevice,
                onSelect: (d) => setState(() {
                  _selectedDevice = d;
                  _isDone = false;
                  _logs = [];
                  _aiAnalysis = null;
                }),
              ),
              const SizedBox(height: 16),
              if (_selectedDevice != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _runDiagnostics,
                    icon: _isRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.play_arrow, size: 20),
                    label: Text(
                      _isRunning
                          ? 'Running Diagnostics...'
                          : _isDone
                              ? 'Re-run Diagnostics'
                              : 'Run Diagnostics',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isRunning ? AppColors.surface : AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (_logs.isNotEmpty)
                TabBar(
                  controller: _tabs,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: [
                    const Tab(text: 'Device Info'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Logs'),
                          const SizedBox(width: 6),
                          if (_isRunning)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('AI Analysis'),
                          if (_isDone && _aiAnalysis != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
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
        if (_logs.isNotEmpty) ...[
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _DeviceInfoTab(device: _selectedDevice!),
                _LogsTab(
                    logs: _logs,
                    isRunning: _isRunning,
                    scrollController: _scrollController),
                _AIAnalysisTab(
                  analysis: _aiAnalysis,
                  rootCause: _rootCause,
                  actions: _suggestedActions,
                  riskLevel: _riskLevel,
                  isDone: _isDone,
                ),
              ],
            ),
          ),
        ] else if (_selectedDevice == null) ...[
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: const Icon(Icons.search,
                        size: 36, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select a device to begin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose from the dropdown above, then tap Run Diagnostics',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_circle_outline,
                        size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedDevice!.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedDevice!.clientName} · ${_selectedDevice!.floor}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'IP: ${_selectedDevice!.ipAddress} · MAC: ${_selectedDevice!.macAddress}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );

    if (!isFullPage) {
      return Scaffold(body: content);
    }
    return content;
  }

  void _exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('NEXUS OPS DIAGNOSTIC REPORT');
    buffer.writeln(
        '==============================');
    buffer.writeln('Device: ${_selectedDevice?.name}');
    buffer.writeln(
        'Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('DIAGNOSTIC LOGS:');
    for (final log in _logs) {
      buffer.writeln(
          '[${_formatTime(log.timestamp)}] ${log.level.padRight(7)} ${log.message}');
    }
    if (_aiAnalysis != null) {
      buffer.writeln('');
      buffer.writeln('AI DIAGNOSIS:');
      buffer.writeln(_aiAnalysis);
      buffer.writeln('');
      buffer.writeln('ROOT CAUSE:');
      buffer.writeln(_rootCause);
      buffer.writeln('');
      buffer.writeln('SUGGESTED ACTIONS:');
      for (int i = 0; i < _suggestedActions.length; i++) {
        buffer.writeln('${i + 1}. ${_suggestedActions[i]}');
      }
      buffer.writeln('');
      buffer.writeln('RISK LEVEL: $_riskLevel');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostic report copied to clipboard'),
        backgroundColor: AppColors.success,
      ),
    );
  }


}

// ─── Device Selector ──────────────────────────────────────────────────────────

class _DeviceSelector extends StatelessWidget {
  final Device? selectedDevice;
  final ValueChanged<Device> onSelect;

  const _DeviceSelector({required this.selectedDevice, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Device>(
          isExpanded: true,
          value: selectedDevice,
          hint: const Text('Select device to troubleshoot...'),
          items: mockDevices
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: d.status == DeviceStatus.offline
                                ? AppColors.error
                                : d.status == DeviceStatus.on
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          d.name,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${d.clientName} · ${d.floor}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (d) {
            if (d != null) onSelect(d);
          },
        ),
      ),
    );
  }
}

// ─── Device Info Tab ──────────────────────────────────────────────────────────

class _DeviceInfoTab extends StatelessWidget {
  final Device device;

  const _DeviceInfoTab({required this.device});

  @override
  Widget build(BuildContext context) {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Status card
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _InfoRow('Device Name', device.name, mono: true),
                _InfoRow('Type', device.type.name.toUpperCase()),
                _InfoRow('Floor', device.floor),
                _InfoRow('Client', device.clientName),
                _InfoRow('IP Address', device.ipAddress, mono: true),
                _InfoRow('MAC Address', device.macAddress, mono: true),
                _InfoRow(
                  'Current Status',
                  device.status.name.toUpperCase(),
                  valueColor: device.status == DeviceStatus.offline
                      ? AppColors.error
                      : device.status == DeviceStatus.on
                          ? AppColors.success
                          : AppColors.textSecondary,
                ),
                _InfoRow(
                  'Schedule Active',
                  device.isOnSchedule ? 'Yes' : 'No',
                  valueColor: device.isOnSchedule
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Schedule
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Schedule',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...days.map((d) {
                  final slot = device.schedule[d] ?? 'OFF';
                  final isToday =
                      d == days[DateTime.now().weekday - 1];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primary.withOpacity(0.08)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isToday ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isToday
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          slot,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: slot == 'OFF'
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isToday) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;

  const _InfoRow(this.label, this.value,
      {this.valueColor, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logs Tab ─────────────────────────────────────────────────────────────────

class _LogsTab extends StatelessWidget {
  final List<DiagnosticLog> logs;
  final bool isRunning;
  final ScrollController scrollController;

  const _LogsTab({
    required this.logs,
    required this.isRunning,
    required this.scrollController,
  });

  Color _levelColor(String level) {
    switch (level) {
      case 'ERROR':
        return AppColors.error;
      case 'WARN':
        return AppColors.warning;
      case 'SUCCESS':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1117),
      child: Column(
        children: [
          // Toolbar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF161B22),
            child: Row(
              children: [
                const Icon(Icons.terminal,
                    color: AppColors.sidebarText, size: 14),
                const SizedBox(width: 8),
                const Text(
                  'diagnostic_output.log',
                  style: TextStyle(
                    color: AppColors.sidebarText,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                if (isRunning)
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                Text(
                  '${logs.length} entries',
                  style: const TextStyle(
                    color: AppColors.sidebarText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: logs.length + (isRunning ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == logs.length) {
                  return Row(
                    children: [
                      Text(
                        '▌',
                        style: TextStyle(
                          color:
                              AppColors.success.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                }
                final log = logs[i];
                final ts =
                    '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.6,
                      ),
                      children: [
                        TextSpan(
                          text: '[$ts] ',
                          style: const TextStyle(
                              color: Color(0xFF6E7681)),
                        ),
                        TextSpan(
                          text: log.level.padRight(7),
                          style: TextStyle(
                            color: _levelColor(log.level),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: log.message,
                          style: TextStyle(
                            color: log.level == 'ERROR'
                                ? AppColors.error
                                : log.level == 'WARN'
                                    ? AppColors.warning
                                    : log.level == 'SUCCESS'
                                        ? AppColors.success
                                        : const Color(0xFFE6EDF3),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Analysis Tab ──────────────────────────────────────────────────────────

class _AIAnalysisTab extends StatelessWidget {
  final String? analysis;
  final String? rootCause;
  final List<String> actions;
  final String riskLevel;
  final bool isDone;

  const _AIAnalysisTab({
    required this.analysis,
    required this.rootCause,
    required this.actions,
    required this.riskLevel,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDone) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Running diagnostics...',
              style:
                  TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final riskColor = riskLevel.startsWith('HIGH')
        ? AppColors.error
        : riskLevel.startsWith('MEDIUM')
            ? AppColors.warning
            : AppColors.success;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Diagnosis header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.psychology,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'AI Diagnosis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  analysis ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  rootCause ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Risk level
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: riskColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  riskLevel.startsWith('HIGH')
                      ? Icons.warning_rounded
                      : riskLevel.startsWith('MEDIUM')
                          ? Icons.info_rounded
                          : Icons.check_circle_rounded,
                  color: riskColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Risk Level: $riskLevel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: riskColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Suggested actions
          const Text(
            'Recommended Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...actions.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ticket created and assigned to facilities team'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.bug_report, size: 16),
                  label: const Text('Create Ticket'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report shared with product team via Slack'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share with Dev Team'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
