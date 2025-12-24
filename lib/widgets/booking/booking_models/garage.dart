class Garage {
  final String garageId;
  final String garageName;
  final String address;
  final double rating;

  Garage({
    required this.garageId,
    required this.garageName,
    required this.address,
    required this.rating,
  });

  factory Garage.fromJson(Map<String, dynamic> json) {
    return Garage(
      garageId: json['garage_id'],
      garageName: json['garage_name'],
      address: json['address'],
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }
}
