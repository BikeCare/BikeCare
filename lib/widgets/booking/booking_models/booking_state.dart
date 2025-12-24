import 'package:flutter/material.dart';

class BookingState {
  // user
  String? userId;

  // step 1
  String? vehicleId;
  String? garageId;

  // step 2
  DateTime? bookingDate;
  TimeOfDay? bookingTime;

  // step 3
  List<String> serviceIds = [];

  BookingState();

  bool get isStep1Valid => vehicleId != null && garageId != null;

  bool get isStep2Valid => bookingDate != null && bookingTime != null;

  bool get isStep3Valid => serviceIds.isNotEmpty;
}
