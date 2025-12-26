import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../helpers/utils.dart';
import 'booking models/booking_state.dart';
import 'booking screens/step1_select_vehicle.dart';
import 'booking screens/step2_select_time.dart';
import 'booking screens/step3_select_service.dart';
import 'booking screens/step4_confirm.dart';
import 'booking screens/step5_success.dart';

class BookingFlow extends StatefulWidget {
  final Map<String, dynamic>? user;
  const BookingFlow({super.key, this.user});

  @override
  State<BookingFlow> createState() => _BookingFlowState();
}

class _BookingFlowState extends State<BookingFlow> {
  int currentStep = 0;
  // Initialize with a fresh state
  BookingState booking = BookingState();
  late Future<Database> _dbFuture; // Future to hold database instance

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      booking.userId = widget.user!['user_id'].toString();
    }
    _dbFuture = initializeDatabase();
  }

  void nextStep() {
    setState(() {
      currentStep++;
    });
  }

  void previousStep() {
    setState(() {
      currentStep--;
    });
  }

  void resetFlow() {
    setState(() {
      currentStep = 0;
      
      // Lưu lại UserID trước khi reset
      String? savedUserId = booking.userId; 
      
      // Tạo object mới (lúc này nó trắng tinh)
      booking = BookingState(); 
      
      // Gán lại UserID cho nó (để không bị null)
      booking.userId = savedUserId; 
      // --------------------
    });
  }

  void _finishBooking() {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Database>(
      future: _dbFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Lỗi Database: ${snapshot.error}')),
          );
        }

        final db = snapshot.data!;

        switch (currentStep) {
          case 0:
            return Step1SelectVehicle(
              booking: booking,
              onNext: nextStep,
              db: db,
            );
          case 1:
            return Step2SelectTime(
              booking: booking,
              onNext: nextStep,
              onBack: previousStep,
            );
          case 2:
            return Step3SelectService(
              booking: booking,
              onNext: nextStep,
              onBack: previousStep,
              db: db,
            );
          case 3:
            return Step4Confirm(
              booking: booking,
              onConfirm: nextStep,
              onBack: previousStep,
              db: db,
            );
          default:
            return Step5Success(onBack: _finishBooking);
        }
      },
    );
  }
}
