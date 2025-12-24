import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bikecare/helpers/utils.dart';
import 'booking_models/booking_state.dart';
import 'booking_screens/step1_select_vehicle.dart';
import 'booking_screens/step2_select_time.dart';
import 'booking_screens/step3_select_service.dart';
import 'booking_screens/step4_confirm.dart';
import 'booking_screens/step5_success.dart';
import 'package:go_router/go_router.dart';

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

  void handleBack() {
    if (currentStep > 0) {
      previousStep(); // về step trước
    } else {
      // đang Step1 -> về homepage
      if (widget.user != null) {
        context.go('/homepage', extra: widget.user);
      } else {
        // nếu lỡ thiếu user thì vẫn về được (tùy router bạn có bắt extra không)
        context.go('/homepage');
      }
    }
  }

  void resetFlow() {
    setState(() {
      currentStep = 0;
      // Reset booking data for new booking
      booking = BookingState();
    });
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
              onBack: handleBack,
              db: db,
            );
          case 1:
            return Step2SelectTime(
              booking: booking,
              onNext: nextStep,
              onBack: handleBack,
            );
          case 2:
            return Step3SelectService(
              booking: booking,
              onNext: nextStep,
              onBack: handleBack,
              db: db,
            );
          case 3:
            return Step4Confirm(
              booking: booking,
              onConfirm: nextStep,
              onBack: handleBack,
              db: db,
            );
          default:
            return Step5Success(onBack: resetFlow);
        }
      },
    );
  }
}
