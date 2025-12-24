import 'package:flutter/material.dart';

class CustomDateTimePicker extends StatelessWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const CustomDateTimePicker({
    super.key,
    this.initialDate,
    this.initialTime,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomDatePicker(
          initialDate: initialDate,
          onDateSelected: onDateChanged,
        ),
        const SizedBox(height: 24),
        CustomTimePicker(
          initialTime: initialTime,
          onTimeSelected: onTimeChanged,
        ),
      ],
    );
  }
}

class CustomDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const CustomDatePicker({
    super.key,
    this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _onMonthChanged(int offset) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + offset,
      );
    });
  }

  void _onDateTapped(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onDateSelected(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF59CBEF)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildWeekDays(),
          const SizedBox(height: 8),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => _onMonthChanged(-1),
        ),
        Text(
          'Tháng ${_displayedMonth.month} ${_displayedMonth.year}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 20),
          onPressed: () => _onMonthChanged(1),
        ),
      ],
    );
  }

  Widget _buildWeekDays() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((day) => SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final offset = firstDayOfMonth.weekday % 7;

    final prevMonthDays = DateTime(_displayedMonth.year, _displayedMonth.month, 0).day;
    const totalCells = 42;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        DateTime date;
        bool isCurrentMonth = true;

        if (index < offset) {
          int day = prevMonthDays - (offset - index - 1);
          date = DateTime(_displayedMonth.year, _displayedMonth.month - 1, day);
          isCurrentMonth = false;
        } else if (index >= offset + daysInMonth) {
          int day = index - (offset + daysInMonth) + 1;
          date = DateTime(_displayedMonth.year, _displayedMonth.month + 1, day);
          isCurrentMonth = false;
        } else {
          int day = index - offset + 1;
          date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
        }

        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;

        return GestureDetector(
          onTap: () => _onDateTapped(date),
          child: Container(
            alignment: Alignment.center,
            decoration: isSelected
                ? const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF59CBEF),
                  )
                : null,
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isCurrentMonth
                        ? Colors.black
                        : Colors.grey.shade300,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}

class CustomTimePicker extends StatefulWidget {
  final TimeOfDay? initialTime;
  final ValueChanged<TimeOfDay> onTimeSelected;
  final VoidCallback? onCancel;

  const CustomTimePicker({
    super.key,
    this.initialTime,
    required this.onTimeSelected,
    this.onCancel,
  });

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  late bool _isAm;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTime ?? TimeOfDay.now();
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    _isAm = t.period == DayPeriod.am;
    
    _hourController = TextEditingController(text: h.toString().padLeft(2, '0'));
    _minuteController = TextEditingController(text: t.minute.toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    int h = int.tryParse(_hourController.text) ?? 12;
    int m = int.tryParse(_minuteController.text) ?? 0;

    // Validate ranges again
    if (h < 1) h = 1;
    if (h > 12) h = 12;
    if (m < 0) m = 0;
    if (m > 59) m = 59;

    // Convert to 24h
    if (_isAm) {
      if (h == 12) h = 0;
    } else {
      if (h != 12) h += 12;
    }
    
    // Safety check
    if (h == 24) h = 0;

    widget.onTimeSelected(TimeOfDay(hour: h, minute: m));
  }

  void _validateHour(String value) {
    if (value.isEmpty) return;
    int? h = int.tryParse(value);
    if (h != null) {
      if (h > 12) h = 12; // Clamp max
      if (h < 1 && value.length >= 2) h = 1; // Clamp min ONLY if reasonable length, else user can't type '1' for '10'
       // Actually user wants "Tự clamp nếu user nhập vượt giới hạn".
       // If user types '9', it is valid. types '13' -> clamp to 12.
       if (h > 12) {
          _hourController.text = '12';
          _hourController.selection = TextSelection.fromPosition(TextPosition(offset: 2));
       }
    }
  }
  
  void _validateMinute(String value) {
    if (value.isEmpty) return;
    int? m = int.tryParse(value);
    if (m != null) {
       if (m > 59) {
          _minuteController.text = '59';
          _minuteController.selection = TextSelection.fromPosition(TextPosition(offset: 2));
       }
    }
  }
  
  void _onHourBlur() {
    int h = int.tryParse(_hourController.text) ?? 12;
    if (h < 1) h = 1;
    if (h > 12) h = 12;
    _hourController.text = h.toString().padLeft(2, '0');
  }

  void _onMinuteBlur() {
    int m = int.tryParse(_minuteController.text) ?? 0;
    if (m > 59) m = 59;
    _minuteController.text = m.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInputBox(_hourController, 'Giờ', (val) => _validateHour(val), _onHourBlur),
            const SizedBox(width: 8),
            Container(
              height: 80,
              alignment: Alignment.center,
              child: const Text(':', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            _buildInputBox(_minuteController, 'Phút', (val) => _validateMinute(val), _onMinuteBlur),
            const SizedBox(width: 16),
            Column(
              children: [
                _buildAmPmButton(true),
                const SizedBox(height: 8),
                _buildAmPmButton(false),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                if (widget.onCancel != null) {
                   widget.onCancel!();
                }
              },
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: _onConfirm,
              child: const Text('OK', style: TextStyle(color: Color(0xFF59CBEF), fontWeight: FontWeight.bold)),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildInputBox(
    TextEditingController controller, 
    String label, 
    ValueChanged<String> onChanged,
    VoidCallback onBlur,
  ) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) onBlur();
            },
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildAmPmButton(bool am) {
    final isActive = am == _isAm;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isAm = am;
        });
      },
      child: Container(
        width: 50,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF59CBEF) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isActive ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          am ? 'AM' : 'PM',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
