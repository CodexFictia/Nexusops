import 'package:flutter/foundation.dart';
import 'models.dart';
import 'mock_data.dart';

// ─── Auth Provider ────────────────────────────────────────────────────────────

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> login(UserRole role, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    if (password != 'nexus123') {
      _error = 'Invalid credentials. Use nexus123';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _currentUser = mockUsers.firstWhere((u) => u.role == role);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}

// ─── App Provider ─────────────────────────────────────────────────────────────

class AppProvider extends ChangeNotifier {
  List<Incident> _incidents = List.from(mockIncidents);
  List<Device> _devices = List.from(mockDevices);
  final List<Client> _clients = List.from(mockClients);
  final List<ExtendedHoursBooking> _bookings = List.from(mockBookings);
  final List<MeterReading> _meters = List.from(mockMeters);
  final List<ExecutiveStatus> _executiveStatuses = List.from(mockExecutiveStatuses);

  // Filters
  IncidentStatus? _incidentFilter;
  String? _floorFilter;
  String _searchQuery = '';

  List<Incident> get incidents => _incidents;
  List<Device> get devices => _devices;
  List<Client> get clients => _clients;
  List<ExtendedHoursBooking> get bookings => _bookings;
  List<MeterReading> get meters => _meters;
  List<ExecutiveStatus> get executiveStatuses => _executiveStatuses;

  String? get floorFilter => _floorFilter;
  IncidentStatus? get incidentFilter => _incidentFilter;

  List<Incident> get openIncidents =>
      _incidents.where((i) => i.status == IncidentStatus.open || i.status == IncidentStatus.inProgress).toList()
        ..sort((a, b) {
          final pa = _priorityValue(a.priority);
          final pb = _priorityValue(b.priority);
          if (pa != pb) return pb.compareTo(pa);
          return b.timestamp.compareTo(a.timestamp);
        });

  List<Incident> get resolvedIncidents =>
      _incidents.where((i) => i.status == IncidentStatus.resolved).toList();

  int get criticalCount =>
      openIncidents.where((i) => i.priority == IncidentPriority.critical).length;

  int get openCount => openIncidents.length;

  List<Incident> incidentsForExecutive(String userId) =>
      openIncidents.where((i) => i.assignedTo == userId || i.assignedTo == null).toList();

  List<Incident> myIncidents(String userId) =>
      openIncidents.where((i) => i.assignedTo == userId).toList();

  List<Client> get criticalClients =>
      _clients.where((c) => c.healthScore < 60).toList()
        ..sort((a, b) => a.healthScore.compareTo(b.healthScore));

  int _priorityValue(IncidentPriority p) {
    switch (p) {
      case IncidentPriority.critical:
        return 4;
      case IncidentPriority.high:
        return 3;
      case IncidentPriority.medium:
        return 2;
      case IncidentPriority.low:
        return 1;
    }
  }

  void resolveIncident(String incidentId, String resolution) {
    final idx = _incidents.indexWhere((i) => i.id == incidentId);
    if (idx == -1) return;
    final old = _incidents[idx];
    _incidents[idx] = Incident(
      id: old.id,
      clientName: old.clientName,
      floor: old.floor,
      description: old.description,
      status: IncidentStatus.resolved,
      priority: old.priority,
      timestamp: old.timestamp,
      assignedTo: old.assignedTo,
      deviceId: old.deviceId,
      resolution: resolution,
      isAfterHours: old.isAfterHours,
    );
    notifyListeners();
  }

  void assignIncident(String incidentId, String userId) {
    final idx = _incidents.indexWhere((i) => i.id == incidentId);
    if (idx == -1) return;
    final old = _incidents[idx];
    _incidents[idx] = Incident(
      id: old.id,
      clientName: old.clientName,
      floor: old.floor,
      description: old.description,
      status: IncidentStatus.inProgress,
      priority: old.priority,
      timestamp: old.timestamp,
      assignedTo: userId,
      deviceId: old.deviceId,
      isAfterHours: old.isAfterHours,
    );
    notifyListeners();
  }

  void toggleDevice(String deviceId) {
    final idx = _devices.indexWhere((d) => d.id == deviceId);
    if (idx == -1) return;
    final d = _devices[idx];
    d.status = d.status == DeviceStatus.on ? DeviceStatus.off : DeviceStatus.on;
    notifyListeners();
  }

  void setFloorFilter(String? floor) {
    _floorFilter = floor;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // KPI helpers
  double get avgResolutionHours {
    final resolved = resolvedIncidents;
    if (resolved.isEmpty) return 0;
    final ages = resolved.map((i) => i.age.inMinutes / 60.0).toList();
    return ages.reduce((a, b) => a + b) / ages.length;
  }

  double get slaCompliancePercent {
    // SLA: resolve within 4 hours
    final resolved = resolvedIncidents;
    if (resolved.isEmpty) return 100;
    final compliant = resolved.where((i) => i.age.inHours <= 4).length;
    return (compliant / resolved.length) * 100;
  }

  double get buildingHealthScore {
    if (_clients.isEmpty) return 0;
    return _clients.map((c) => c.healthScore).reduce((a, b) => a + b) / _clients.length;
  }
}
