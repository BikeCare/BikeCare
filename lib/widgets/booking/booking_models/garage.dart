class Garage {
  final String id;
  final String name;
  final String address;
  final double rating;

  Garage({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
  });

  factory Garage.fromJson(Map<String, dynamic> json) {
    return Garage(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Cửa hàng không tên').toString(),
      address: json['address'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }
}
