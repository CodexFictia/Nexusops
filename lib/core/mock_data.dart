import 'models.dart';

// ─── Users ────────────────────────────────────────────────────────────────────

final mockUsers = [
  const AppUser(
    id: 'u1',
    name: 'Raj Sharma',
    email: 'raj.sharma@smartworks.com',
    role: UserRole.executive,
    initials: 'RS',
    assignedBuilding: 'DLF Commercial, Tower A',
  ),
  const AppUser(
    id: 'u2',
    name: 'Priya Nair',
    email: 'priya.nair@smartworks.com',
    role: UserRole.accountManager,
    initials: 'PN',
    assignedBuilding: 'DLF Commercial, Tower A',
  ),
  const AppUser(
    id: 'u3',
    name: 'Amit Verma',
    email: 'amit.verma@smartworks.com',
    role: UserRole.centreHead,
    initials: 'AV',
    assignedBuilding: 'DLF Commercial, Tower A',
  ),
  const AppUser(
    id: 'u4',
    name: 'Sunita Rao',
    email: 'sunita.rao@smartworks.com',
    role: UserRole.executive,
    initials: 'SR',
    assignedBuilding: 'DLF Commercial, Tower A',
  ),
  const AppUser(
    id: 'u5',
    name: 'Deepak Singh',
    email: 'deepak.singh@smartworks.com',
    role: UserRole.executive,
    initials: 'DS',
    assignedBuilding: 'DLF Commercial, Tower A',
  ),
];

// ─── Clients ──────────────────────────────────────────────────────────────────

final mockClients = [
  Client(
    id: 'c1',
    name: 'CAP ALPHA Investment Managers Pvt Ltd',
    floor: '2nd Floor',
    deviceCount: 3,
    csatScore: 3.8,
    healthScore: 55,
    contractEnd: DateTime(2026, 9, 30),
    contactName: 'Vikram Malhotra',
    contactEmail: 'vikram@capalpha.in',
    openIncidents: 2,
    issues: ['Unauthorized power change', 'No schedule match'],
  ),
  Client(
    id: 'c2',
    name: 'Hexagon Capability Center India Pvt. Ltd.',
    floor: 'Ground Floor',
    deviceCount: 1,
    csatScore: 4.1,
    healthScore: 62,
    contractEnd: DateTime(2026, 12, 31),
    contactName: 'Shweta Kapoor',
    contactEmail: 'shweta@hexagon.com',
    openIncidents: 3,
    issues: ['Power off outside schedule', 'Meter anomaly'],
  ),
  Client(
    id: 'c3',
    name: 'GMG International Private Limited',
    floor: '2nd Floor',
    deviceCount: 2,
    csatScore: 4.5,
    healthScore: 80,
    contractEnd: DateTime(2026, 6, 30),
    contactName: 'Ravi Kumar',
    contactEmail: 'ravi@gmgintl.com',
    openIncidents: 1,
    issues: ['Unauthorized power change'],
  ),
  Client(
    id: 'c4',
    name: 'FNZ Technology',
    floor: 'Ground Floor',
    deviceCount: 2,
    csatScore: 4.7,
    healthScore: 91,
    contractEnd: DateTime(2027, 3, 31),
    contactName: 'Ananya Patel',
    contactEmail: 'ananya@fnz.com',
    openIncidents: 0,
    issues: [],
  ),
  Client(
    id: 'c5',
    name: 'Fedex Express Transportation',
    floor: '2nd Floor',
    deviceCount: 1,
    csatScore: 4.3,
    healthScore: 85,
    contractEnd: DateTime(2026, 11, 30),
    contactName: 'Mohan Iyer',
    contactEmail: 'mohan@fedex.com',
    openIncidents: 0,
    issues: [],
  ),
  Client(
    id: 'c6',
    name: 'Nomura Services India Private Limited',
    floor: '2nd Floor',
    deviceCount: 1,
    csatScore: 4.6,
    healthScore: 95,
    contractEnd: DateTime(2027, 1, 31),
    contactName: 'Kavya Reddy',
    contactEmail: 'kavya@nomura.com',
    openIncidents: 0,
    issues: [],
  ),
  Client(
    id: 'c7',
    name: 'Hollister Global Business',
    floor: '3rd Floor',
    deviceCount: 1,
    csatScore: 3.5,
    healthScore: 48,
    contractEnd: DateTime(2026, 5, 31),
    contactName: 'Sanjay Mehta',
    contactEmail: 'sanjay@hollister.com',
    openIncidents: 4,
    issues: ['Device offline', 'HVAC alert', 'Meter silence', 'Schedule mismatch'],
  ),
  Client(
    id: 'c8',
    name: 'Provoltus Energy Services',
    floor: '3rd Floor',
    deviceCount: 1,
    csatScore: 4.0,
    healthScore: 72,
    contractEnd: DateTime(2026, 8, 31),
    contactName: 'Neha Gupta',
    contactEmail: 'neha@provoltus.com',
    openIncidents: 1,
    issues: ['Consumption spike'],
  ),
  Client(
    id: 'c9',
    name: 'E R M India Pvt Ltd',
    floor: '2nd Floor',
    deviceCount: 2,
    csatScore: 4.4,
    healthScore: 88,
    contractEnd: DateTime(2027, 2, 28),
    contactName: 'Arjun Das',
    contactEmail: 'arjun@erm.com',
    openIncidents: 0,
    issues: [],
  ),
  Client(
    id: 'c10',
    name: 'Talbotforce Services Private Limited',
    floor: '1st Floor',
    deviceCount: 1,
    csatScore: 4.2,
    healthScore: 78,
    contractEnd: DateTime(2026, 10, 31),
    contactName: 'Pooja Sharma',
    contactEmail: 'pooja@talbotforce.com',
    openIncidents: 1,
    issues: ['Meter anomaly'],
  ),
  Client(
    id: 'c11',
    name: 'MAAP Marketing LLP',
    floor: '3rd Floor',
    deviceCount: 1,
    csatScore: 4.1,
    healthScore: 70,
    contractEnd: DateTime(2026, 7, 31),
    contactName: 'Rahul Joshi',
    contactEmail: 'rahul@maap.in',
    openIncidents: 2,
    issues: ['Device offline', 'Unauthorized access'],
  ),
];

// ─── Incidents ────────────────────────────────────────────────────────────────

final mockIncidents = [
  Incident(
    id: 'b2a1f5c3-19d7-44c6-81ea-323ee6cbe41d',
    clientName: 'CAP ALPHA Investment Managers Pvt Ltd',
    floor: '2nd Floor',
    description: 'Unauthorized power change detected — no matching schedule or command',
    status: IncidentStatus.open,
    priority: IncidentPriority.high,
    timestamp: DateTime.now().subtract(const Duration(hours: 11, minutes: 15)),
    deviceId: 'dev-sonoff-2f-capalpha',
    isAfterHours: true,
  ),
  Incident(
    id: 'b17802ce-fcf9-4c8d-b805-405e11c24a81',
    clientName: 'Hexagon Capability Center India Pvt. Ltd.',
    floor: 'Ground Floor',
    description: 'Unauthorized power change detected — no matching schedule or command',
    status: IncidentStatus.open,
    priority: IncidentPriority.high,
    timestamp: DateTime.now().subtract(const Duration(hours: 11, minutes: 15)),
    deviceId: 'dev-sonoff-gf-hexagon',
    isAfterHours: true,
  ),
  Incident(
    id: 'c40c08ab-1a85-4e03-9798-628b8b15a792',
    clientName: 'GMG International Private Limited',
    floor: '2nd Floor',
    description: 'Unauthorized power change detected — no matching schedule or command',
    status: IncidentStatus.open,
    priority: IncidentPriority.medium,
    timestamp: DateTime.now().subtract(const Duration(hours: 15, minutes: 45)),
    deviceId: 'dev-sonoff-2f-gmg',
    isAfterHours: true,
  ),
  Incident(
    id: 'b37765b2-a2ae-4884-9fdc-64004b427345',
    clientName: 'Hexagon Capability Center India Pvt. Ltd.',
    floor: 'Ground Floor',
    description: 'Unauthorized power change detected — no matching schedule or command',
    status: IncidentStatus.open,
    priority: IncidentPriority.high,
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 11, minutes: 15)),
    deviceId: 'dev-sonoff-gf-hexagon',
    isAfterHours: true,
  ),
  Incident(
    id: 'e5f2a1b3-0012-4abc-8def-112233445566',
    clientName: 'Hollister Global Business',
    floor: '3rd Floor',
    description: 'Sonoff device offline — not responding to ping. Schedule window active.',
    status: IncidentStatus.open,
    priority: IncidentPriority.critical,
    timestamp: DateTime.now().subtract(const Duration(minutes: 34)),
    deviceId: 'dev-sonoff-3f-hollister',
    assignedTo: 'u1',
  ),
  Incident(
    id: 'f6a3b2c4-0123-4bcd-9ef0-223344556677',
    clientName: 'Hollister Global Business',
    floor: '3rd Floor',
    description: 'HVAC unit not responding — temperature rising above comfort threshold',
    status: IncidentStatus.inProgress,
    priority: IncidentPriority.critical,
    timestamp: DateTime.now().subtract(const Duration(minutes: 52)),
    deviceId: 'dev-hvac-3f-hollister',
    assignedTo: 'u1',
  ),
  Incident(
    id: 'g7b4c3d5-0234-4cde-0f01-334455667788',
    clientName: 'Provoltus Energy Services',
    floor: '3rd Floor',
    description: 'Consumption spike detected — 340% above baseline. Meter ID: GF-3 CS ER-1',
    status: IncidentStatus.open,
    priority: IncidentPriority.medium,
    timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
    deviceId: 'dev-meter-3f-provoltus',
  ),
  Incident(
    id: 'h8c5d4e6-0345-4def-1012-445566778899',
    clientName: 'MAAP Marketing LLP',
    floor: '3rd Floor',
    description: 'Access control device offline — FR/RFID entries not being logged',
    status: IncidentStatus.open,
    priority: IncidentPriority.high,
    timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 22)),
    deviceId: 'dev-ac-3f-maap',
  ),
  Incident(
    id: 'i9d6e5f7-0456-4ef0-2123-556677889900',
    clientName: 'Talbotforce Services Private Limited',
    floor: '1st Floor',
    description: 'Meter silence — no readings received for 2+ hours',
    status: IncidentStatus.open,
    priority: IncidentPriority.medium,
    timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 35)),
    deviceId: 'dev-meter-1f-talbotforce',
  ),
  // Resolved
  Incident(
    id: 'j0e7f6g8-0567-4f01-3234-667788990011',
    clientName: 'FNZ Technology',
    floor: 'Ground Floor',
    description: 'Common area lights not switching on during schedule window',
    status: IncidentStatus.resolved,
    priority: IncidentPriority.medium,
    timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 15)),
    deviceId: 'dev-sonoff-gf-fnz',
    assignedTo: 'u4',
    resolution: 'Device rebooted via admin panel. Schedule re-synced. Root cause: firmware update caused schedule wipe.',
  ),
];

// ─── Devices ──────────────────────────────────────────────────────────────────

final mockDevices = [
  Device(
    id: 'dev-sonoff-2f-capalpha',
    name: 'SONOFF-2F-CAPALPHA',
    type: DeviceType.sonoff,
    status: DeviceStatus.on,
    floor: '2nd Floor',
    clientName: 'CAP ALPHA Investment Managers Pvt Ltd',
    schedule: {
      'MON': '08:00-20:00',
      'TUE': '08:00-20:00',
      'WED': '08:00-20:00',
      'THU': '08:00-20:00',
      'FRI': '08:00-20:00',
      'SAT': '08:00-14:00',
      'SUN': 'OFF',
    },
    ipAddress: '192.168.1.42',
    macAddress: 'AA:BB:CC:11:22:33',
  ),
  Device(
    id: 'dev-sonoff-gf-hexagon',
    name: 'SONOFF-GF-HEXAGON',
    type: DeviceType.sonoff,
    status: DeviceStatus.on,
    floor: 'Ground Floor',
    clientName: 'Hexagon Capability Center India Pvt. Ltd.',
    schedule: {
      'MON': '08:00-20:00',
      'TUE': '08:00-20:00',
      'WED': '08:00-20:00',
      'THU': '08:00-20:00',
      'FRI': '08:00-20:00',
      'SAT': '08:00-14:00',
      'SUN': 'OFF',
    },
    ipAddress: '192.168.1.38',
    macAddress: 'AA:BB:CC:44:55:66',
  ),
  Device(
    id: 'dev-sonoff-2f-gmg',
    name: 'SONOFF-2F-GMG',
    type: DeviceType.sonoff,
    status: DeviceStatus.on,
    floor: '2nd Floor',
    clientName: 'GMG International Private Limited',
    schedule: {
      'MON': '09:00-19:00',
      'TUE': '09:00-19:00',
      'WED': '09:00-19:00',
      'THU': '09:00-19:00',
      'FRI': '09:00-19:00',
      'SAT': 'OFF',
      'SUN': 'OFF',
    },
    ipAddress: '192.168.1.55',
    macAddress: 'AA:BB:CC:77:88:99',
  ),
  Device(
    id: 'dev-sonoff-3f-hollister',
    name: 'SONOFF-3F-HOLLISTER',
    type: DeviceType.sonoff,
    status: DeviceStatus.offline,
    floor: '3rd Floor',
    clientName: 'Hollister Global Business',
    schedule: {
      'MON': '08:00-20:00',
      'TUE': '08:00-20:00',
      'WED': '08:00-20:00',
      'THU': '08:00-20:00',
      'FRI': '08:00-20:00',
      'SAT': '08:00-14:00',
      'SUN': 'OFF',
    },
    ipAddress: '192.168.1.61',
    macAddress: 'AA:BB:CC:AA:BB:CC',
  ),
  Device(
    id: 'dev-sonoff-gf-fnz',
    name: 'SONOFF-GF-FNZ-1',
    type: DeviceType.sonoff,
    status: DeviceStatus.off,
    floor: 'Ground Floor',
    clientName: 'FNZ Technology',
    schedule: {
      'MON': '08:00-20:00',
      'TUE': '08:00-20:00',
      'WED': '08:00-20:00',
      'THU': '08:00-20:00',
      'FRI': '08:00-20:00',
      'SAT': 'OFF',
      'SUN': 'OFF',
    },
    ipAddress: '192.168.1.72',
    macAddress: 'AA:BB:CC:DD:EE:FF',
  ),
  Device(
    id: 'dev-sonoff-2f-nomura',
    name: 'SONOFF-2F-NOMURA',
    type: DeviceType.sonoff,
    status: DeviceStatus.on,
    floor: '2nd Floor',
    clientName: 'Nomura Services India Private Limited',
    schedule: {
      'MON': '00:00-23:59',
      'TUE': '00:00-23:59',
      'WED': '00:00-23:59',
      'THU': '00:00-23:59',
      'FRI': '00:00-23:59',
      'SAT': '00:00-23:59',
      'SUN': 'OFF',
    },
    ipAddress: '192.168.1.83',
    macAddress: '11:22:33:44:55:66',
  ),
];

// ─── Extended Hours Bookings ───────────────────────────────────────────────────

final mockBookings = [
  ExtendedHoursBooking(
    id: '64f6e13d-95c3-45ec-8898-812f4a8b8b8c',
    clientName: 'E R M India Pvt Ltd',
    floor: '2nd Floor',
    date: DateTime.now(),
    timeRange: '8:00 AM–11:59 PM',
    duration: '15h 59m',
    source: BookingSource.ops,
    billable: false,
    status: BookingStatus.ongoing,
  ),
  ExtendedHoursBooking(
    id: 'eccb435b-18eb-4bc5-8859-589b53978dcb',
    clientName: 'E R M India Pvt Ltd',
    floor: '2nd Floor',
    date: DateTime.now(),
    timeRange: '12:00 AM–2:00 AM',
    duration: '2h',
    source: BookingSource.ops,
    billable: false,
    status: BookingStatus.completed,
  ),
  ExtendedHoursBooking(
    id: '618e9d06-077f-42c9-970e-da82a1881358',
    clientName: 'Nomura Services India Private Limited',
    floor: '2nd Floor',
    date: DateTime.now(),
    timeRange: '7:34 AM–8:00 AM',
    duration: '0h 26m',
    source: BookingSource.ops,
    billable: false,
    status: BookingStatus.completed,
  ),
  ExtendedHoursBooking(
    id: 'c4687620-133c-449b-bd08-3471f7290207',
    clientName: 'Nomura Services India Private Limited',
    floor: '2nd Floor',
    date: DateTime.now().subtract(const Duration(days: 3)),
    timeRange: '1:00 PM–4:00 PM',
    duration: '3h',
    source: BookingSource.ops,
    billable: true,
    status: BookingStatus.completed,
  ),
];

// ─── Meter Readings ───────────────────────────────────────────────────────────

final mockMeters = [
  MeterReading(
    meterId: 'gf-1-lp-er2',
    meterName: 'Ground Floor 1 L+P (ER-2)',
    floor: 'Ground Floor',
    clientName: 'Common Area',
    hourlyKwh: [
      2.1, 1.8, 1.9, 2.0, 2.3, 3.1, 5.2, 8.4, 10.2, 12.1, 13.5, 14.2,
      14.8, 13.9, 12.7, 11.3, 9.8, 8.2, 6.7, 5.1, 4.3, 3.8, 3.2, 2.7,
    ],
    anomalies: [
      false, false, false, false, false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false, false, false, false, false,
    ],
  ),
  MeterReading(
    meterId: 'gf-1-lp-er1',
    meterName: 'Ground Floor 1 L+P (ER-1)',
    floor: 'Ground Floor',
    clientName: 'Common Area',
    hourlyKwh: [
      120, 98, 105, 110, 135, 280, 1800, 4200, 7800, 9500, 10200, 11500,
      12000, 11800, 10500, 9200, 7800, 6200, 4800, 3200, 2100, 1800, 1400, 950,
    ],
    anomalies: [
      false, false, false, false, false, false, true, false, false, false, false, false,
      false, false, false, false, false, false, false, false, false, false, false, false,
    ],
  ),
  MeterReading(
    meterId: '3f-cs-er1',
    meterName: 'Ground Floor 3 CS (ER-1)',
    floor: '3rd Floor',
    clientName: 'Provoltus Energy Services',
    hourlyKwh: [
      580, 620, 590, 610, 640, 750, 820, 890, 920, 960, 980, 2940,
      960, 940, 920, 890, 850, 820, 780, 720, 680, 640, 610, 590,
    ],
    anomalies: [
      false, false, false, false, false, false, false, false, false, false, false, true,
      false, false, false, false, false, false, false, false, false, false, false, false,
    ],
  ),
];

// ─── Executive Statuses ───────────────────────────────────────────────────────

final mockExecutiveStatuses = [
  ExecutiveStatus(
    executive: mockUsers[0], // Raj Sharma
    currentIncident: mockIncidents[4], // Hollister offline
    location: '3rd Floor',
    lastSeen: DateTime.now().subtract(const Duration(minutes: 3)),
    resolvedToday: 4,
  ),
  ExecutiveStatus(
    executive: mockUsers[3], // Sunita Rao
    currentIncident: mockIncidents[7], // MAAP access control
    location: '3rd Floor',
    lastSeen: DateTime.now().subtract(const Duration(minutes: 8)),
    resolvedToday: 3,
  ),
  ExecutiveStatus(
    executive: mockUsers[4], // Deepak Singh
    currentIncident: null,
    location: 'Ground Floor',
    lastSeen: DateTime.now().subtract(const Duration(minutes: 1)),
    resolvedToday: 6,
  ),
];

// ─── Building Summary ─────────────────────────────────────────────────────────

class BuildingSummary {
  static const String name = 'DLF Commercial, Tower A';
  static const String city = 'Gurugram, Delhi NCR';
  static const int totalFloors = 6;
  static const int totalClients = 11;
  static const int totalDevices = 44;
  static const double overallCsat = 4.2;
  static const double targetCsat = 4.8;
  static const int openIncidents = 20;
  static const int resolvedThisMonth = 1;
  static const int totalBookingsMonth = 16;
  static const double avgBookingDuration = 5.8;
  static const double monthlyRevenue = 1485000; // INR
  static const double revenueAtRisk = 120000; // INR due to incidents
}
