class Service {
  final String serviceId;
  final String serviceName;

  Service({required this.serviceId, required this.serviceName});

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      serviceId: json['service_id'],
      serviceName: json['service_name'],
    );
  }
}
