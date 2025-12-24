class Vehicle {
  final String vehicleId;
  final String vehicleName;
  final String brand;
  final String licensePlate;

  Vehicle({
    required this.vehicleId,
    required this.vehicleName,
    required this.brand,
    required this.licensePlate,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicle_id'],
      vehicleName: json['vehicle_name'],
      brand: json['brand'],
      licensePlate: json['license_plate'],
    );
  }
}
