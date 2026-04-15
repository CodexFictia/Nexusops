import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/models.dart';

// ─── Stat Card ────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? valueColor;
  final Color? accentColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.valueColor,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 15, color: accent),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: valueColor ?? accent,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── KPI Grid ─────────────────────────────────────────────────────────────────

class KpiGrid extends StatelessWidget {
  final List<Widget> cards;

  const KpiGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: cards,
      );
    }
    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

// ─── Priority Badge ───────────────────────────────────────────────────────────

class PriorityBadge extends StatelessWidget {
  final IncidentPriority priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (priority) {
      case IncidentPriority.critical:
        bg = AppColors.errorBg;
        fg = AppColors.error;
        label = 'CRITICAL';
        break;
      case IncidentPriority.high:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        label = 'HIGH';
        break;
      case IncidentPriority.medium:
        bg = AppColors.infoBg;
        fg = AppColors.info;
        label = 'MEDIUM';
        break;
      case IncidentPriority.low:
        bg = AppColors.successBg;
        fg = AppColors.success;
        label = 'LOW';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Status Dot ───────────────────────────────────────────────────────────────

class StatusDot extends StatelessWidget {
  final Color color;
  final bool pulse;
  final double size;

  const StatusDot({
    super.key,
    required this.color,
    this.pulse = false,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: pulse
            ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4, spreadRadius: 2)]
            : null,
      ),
    );
  }
}

// ─── Incident Card ────────────────────────────────────────────────────────────

class IncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback? onResolve;
  final VoidCallback? onTroubleshoot;
  final VoidCallback? onAssign;
  final bool showActions;
  final bool compact;

  const IncidentCard({
    super.key,
    required this.incident,
    this.onResolve,
    this.onTroubleshoot,
    this.onAssign,
    this.showActions = true,
    this.compact = false,
  });

  Color get _leftBorderColor {
    switch (incident.priority) {
      case IncidentPriority.critical:
        return AppColors.error;
      case IncidentPriority.high:
        return AppColors.warning;
      case IncidentPriority.medium:
        return AppColors.info;
      case IncidentPriority.low:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(width: 4, color: _leftBorderColor),
              // Card content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(compact ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusDot(
                            color: incident.status == IncidentStatus.resolved
                                ? AppColors.success
                                : incident.status == IncidentStatus.inProgress
                                    ? AppColors.info
                                    : AppColors.error,
                            pulse: incident.status == IncidentStatus.inProgress,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              incident.id.substring(0, 8).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          PriorityBadge(priority: incident.priority),
                          const SizedBox(width: 8),
                          Text(
                            incident.ageLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${incident.clientName} — ${incident.floor}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        incident.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (incident.status == IncidentStatus.resolved &&
                          incident.resolution != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.success.withOpacity(0.25)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 14, color: AppColors.success),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  incident.resolution!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (showActions && !compact) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            if (onTroubleshoot != null)
                              OutlinedButton.icon(
                                onPressed: onTroubleshoot,
                                icon: const Icon(Icons.terminal, size: 16),
                                label: const Text('Troubleshoot'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                              ),
                            const SizedBox(width: 8),
                            if (onAssign != null)
                              OutlinedButton.icon(
                                onPressed: onAssign,
                                icon: const Icon(Icons.person_add, size: 16),
                                label: const Text('Assign'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                              ),
                            const Spacer(),
                            if (onResolve != null)
                              ElevatedButton.icon(
                                onPressed: onResolve,
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Resolve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ],
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

// ─── Device Tile ──────────────────────────────────────────────────────────────

class DeviceTile extends StatelessWidget {
  final Device device;
  final VoidCallback? onToggle;
  final VoidCallback? onTroubleshoot;

  const DeviceTile({
    super.key,
    required this.device,
    this.onToggle,
    this.onTroubleshoot,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = device.status != DeviceStatus.offline;
    final isOn = device.status == DeviceStatus.on;
    final scheduleMatch = device.isOnSchedule;

    Color statusColor;
    String statusLabel;
    if (!isOnline) {
      statusColor = AppColors.error;
      statusLabel = 'Offline';
    } else if (isOn) {
      statusColor = AppColors.success;
      statusLabel = 'ON';
    } else {
      statusColor = AppColors.textSecondary;
      statusLabel = 'OFF';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isOn
                ? AppColors.warningBg
                : isOnline
                    ? AppColors.surface
                    : AppColors.errorBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            device.type == DeviceType.sonoff
                ? Icons.power
                : device.type == DeviceType.hvac
                    ? Icons.air
                    : device.type == DeviceType.smartMeter
                        ? Icons.electric_meter
                        : Icons.lock,
            color: isOn
                ? AppColors.warning
                : isOnline
                    ? AppColors.textSecondary
                    : AppColors.error,
            size: 22,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${device.clientName} · ${device.floor}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                StatusDot(color: statusColor, size: 6),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600),
                ),
                if (isOn && !scheduleMatch) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Outside Schedule',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onTroubleshoot != null)
              IconButton(
                icon: const Icon(Icons.terminal, size: 18),
                onPressed: onTroubleshoot,
                tooltip: 'Troubleshoot',
                color: AppColors.textSecondary,
              ),
            if (onToggle != null && isOnline)
              Switch(
                value: isOn,
                onChanged: (_) => onToggle!(),
                activeColor: AppColors.success,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Health Score Bar ─────────────────────────────────────────────────────────

class HealthBar extends StatelessWidget {
  final double score;
  final double height;

  const HealthBar({super.key, required this.score, this.height = 6});

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: score / 100,
        minHeight: height,
        backgroundColor: AppColors.border,
        valueColor: AlwaysStoppedAnimation<Color>(_color),
      ),
    );
  }
}

// ─── Resolve Dialog ───────────────────────────────────────────────────────────

Future<String?> showResolveDialog(BuildContext context, Incident incident) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Resolve Incident'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            incident.clientName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(incident.description,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe what was done to resolve this...',
              labelText: 'Resolution Notes',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, controller.text.isEmpty
              ? 'Resolved by operator'
              : controller.text),
          child: const Text('Mark Resolved'),
        ),
      ],
    ),
  );
}
