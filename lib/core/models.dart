import 'package:flutter/material.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

enum UserRole { executive, accountManager, centreHead }

enum IncidentStatus { open, inProgress, resolved, escalated }

enum IncidentPriority { critical, high, medium, low }

enum DeviceType { sonoff, smartMeter, hvac, accessControl }

enum DeviceStatus { on, off, offline, unknown }

enum BookingSource { ops, client, system }

enum BookingStatus { ongoing, completed, upcoming, cancelled }

// ─── Models ──────────────────────────────────────────────────────────────────

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String initials;
  final String? assignedBuilding;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.initials,
    this.assignedBuilding,
  });
}

class Client {
  final String id;
  final String name;
  final String floor;
  final int deviceCount;
  final double csatScore;
  final double healthScore; // 0-100
  final DateTime contractEnd;
  final String contactName;
  final String contactEmail;
  final int openIncidents;
  final List<String> issues;

  const Client({
    required this.id,
    required this.name,
    required this.floor,
    required this.deviceCount,
    required this.csatScore,
    required this.healthScore,
    required this.contractEnd,
    required this.contactName,
    required this.contactEmail,
    required this.openIncidents,
    required this.issues,
  });

  String get healthLabel {
    if (healthScore >= 80) return 'Healthy';
    if (healthScore >= 60) return 'At Risk';
    return 'Critical';
  }
}

class Incident {
  final String id;
  final String clientName;
  final String floor;
  final String description;
  final IncidentStatus status;
  final IncidentPriority priority;
  final DateTime timestamp;
  final String? assignedTo;
  final String deviceId;
  final String? resolution;
  final bool isAfterHours;

  const Incident({
    required this.id,
    required this.clientName,
    required this.floor,
    required this.description,
    required this.status,
    required this.priority,
    required this.timestamp,
    this.assignedTo,
    required this.deviceId,
    this.resolution,
    this.isAfterHours = false,
  });

  Duration get age => DateTime.now().difference(timestamp);

  String get ageLabel {
    final h = age.inHours;
    final m = age.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m ago';
    return '${m}m ago';
  }
}

class Device {
  final String id;
  final String name;
  final DeviceType type;
  DeviceStatus status;
  final String floor;
  final String clientName;
  final Map<String, String> schedule; // day -> "HH:MM-HH:MM" or "OFF"
  final String ipAddress;
  final String macAddress;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.floor,
    required this.clientName,
    required this.schedule,
    required this.ipAddress,
    required this.macAddress,
  });

  bool get isOnSchedule {
    final now = DateTime.now();
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final dayKey = days[now.weekday - 1];
    final slot = schedule[dayKey];
    if (slot == null || slot == 'OFF') return false;
    final parts = slot.split('-');
    if (parts.length != 2) return false;
    final startParts = parts[0].split(':');
    final endParts = parts[1].split(':');
    final start =
        TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
    final end =
        TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
    final current = TimeOfDay.fromDateTime(now);
    final currentMins = current.hour * 60 + current.minute;
    final startMins = start.hour * 60 + start.minute;
    final endMins = end.hour * 60 + end.minute;
    return currentMins >= startMins && currentMins <= endMins;
  }
}

class ExtendedHoursBooking {
  final String id;
  final String clientName;
  final String floor;
  final DateTime date;
  final String timeRange;
  final String duration;
  final BookingSource source;
  final bool billable;
  final BookingStatus status;

  const ExtendedHoursBooking({
    required this.id,
    required this.clientName,
    required this.floor,
    required this.date,
    required this.timeRange,
    required this.duration,
    required this.source,
    required this.billable,
    required this.status,
  });
}

class MeterReading {
  final String meterId;
  final String meterName;
  final String floor;
  final String clientName;
  final List<double> hourlyKwh; // 24 values
  final List<bool> anomalies; // 24 flags

  const MeterReading({
    required this.meterId,
    required this.meterName,
    required this.floor,
    required this.clientName,
    required this.hourlyKwh,
    required this.anomalies,
  });

  double get totalKwh => hourlyKwh.fold(0, (a, b) => a + b);
  int get anomalyCount => anomalies.where((a) => a).length;
}

class ExecutiveStatus {
  final AppUser executive;
  final Incident? currentIncident;
  final String location;
  final DateTime lastSeen;
  final int resolvedToday;

  const ExecutiveStatus({
    required this.executive,
    this.currentIncident,
    required this.location,
    required this.lastSeen,
    required this.resolvedToday,
  });
}

class DiagnosticLog {
  final DateTime timestamp;
  final String level; // INFO, WARN, ERROR, SUCCESS
  final String message;

  const DiagnosticLog({
    required this.timestamp,
    required this.level,
    required this.message,
  });
}
