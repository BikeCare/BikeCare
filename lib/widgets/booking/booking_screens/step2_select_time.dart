import 'package:flutter/material.dart';
import '../booking_models/booking_state.dart';
import '../booking_widgets/custom_date_time_picker.dart';
import '../booking_widgets/booking_progress_header.dart';

class Step2SelectTime extends StatefulWidget {
  final BookingState booking;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step2SelectTime({
    super.key,
    required this.booking,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<Step2SelectTime> createState() => _Step2SelectTimeState();
}

enum _PickerType { none, date, time }

class _Step2SelectTimeState extends State<Step2SelectTime> {
  _PickerType _activePicker = _PickerType.none;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onBack,
        ),
        centerTitle: true,
        title: const Text(
          'Đặt lịch bảo dưỡng',
          style: TextStyle(
            color: Color(0xFF59CBEF),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BookingProgressHeader(currentStep: 2),

              const SizedBox(height: 24),

              const Text(
                'Chọn ngày bảo dưỡng*',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _PickerField(
                hint: 'DD/MM/YYYY',
                value: widget.booking.bookingDate == null
                    ? null
                    : _formatDate(widget.booking.bookingDate!),
                icon: Icons.calendar_today_outlined,
                onTap: () {
                  setState(() {
                    _activePicker = _PickerType.date;
                  });
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Chọn thời gian*',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _PickerField(
                hint: 'HH:MM AM',
                value: widget.booking.bookingTime?.format(context),
                icon: Icons.access_time,
                onTap: () {
                  setState(() {
                    _activePicker = _PickerType.time;
                  });
                },
              ),

              // ===== CUSTOM PICKER INLINE =====
              if (_activePicker == _PickerType.date)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: CustomDatePicker(
                    initialDate: widget.booking.bookingDate,
                    onDateSelected: (date) {
                      setState(() {
                        widget.booking.bookingDate = date;
                        _activePicker = _PickerType.none;
                      });
                    },
                  ),
                ),

              if (_activePicker == _PickerType.time)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF59CBEF)),
                    ),
                    child: CustomTimePicker(
                      initialTime: widget.booking.bookingTime,
                      onTimeSelected: (time) {
                        setState(() {
                          widget.booking.bookingTime = time;
                          _activePicker = _PickerType.none;
                        });
                      },
                      onCancel: () {
                        setState(() {
                          _activePicker = _PickerType.none;
                        });
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              Center(
                child: SizedBox(
                  width: 180,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: widget.booking.isStep2Valid
                        ? widget.onNext
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF59CBEF),
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: const Color(0xFFFFC107),
                      disabledForegroundColor: const Color(0xFF5B4706),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Tiếp theo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =======================
/// PICKER FIELD
/// =======================
class _PickerField extends StatelessWidget {
  final String hint;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerField({
    required this.hint,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF59CBEF)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              value ?? hint,
              style: TextStyle(
                color: value == null ? Colors.grey : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
