class DriverTelemetry {
  final String driverCode;
  final String? teamName;
  final DateTime date;
  final double sessionTime;
  final double lapTime;
  final double rpm;
  final double speed;
  final int gear;
  final double throttle;
  final bool brake;
  final double brakePressure;
  final int drs;
  final double x;
  final double y;
  final double z;
  final double distance;
  final double relativeDistance;
  final String driverAhead;
  final double distanceToDriverAhead;
  final String status;
  final String source;

  DriverTelemetry({
    required this.driverCode,
    this.teamName,
    required this.date,
    required this.sessionTime,
    required this.lapTime,
    required this.rpm,
    required this.speed,
    required this.gear,
    required this.throttle,
    required this.brake,
    this.brakePressure = 0,
    required this.drs,
    required this.x,
    required this.y,
    required this.z,
    required this.distance,
    required this.relativeDistance,
    required this.driverAhead,
    required this.distanceToDriverAhead,
    required this.status,
    required this.source,
  });
  @override
  String toString() {
    return 'Driver: $driverCode | Team: ${teamName ?? 'N/A'} | Speed: $speed | Gear: $gear | Throttle: $throttle | DistanceAhead: $distanceToDriverAhead';
  }
}
