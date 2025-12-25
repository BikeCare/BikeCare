import 'package:flutter/material.dart';

class BookingProgressHeader extends StatelessWidget {
  final int currentStep;

  const BookingProgressHeader({
    super.key,
    required this.currentStep,
  });

  static const Color _activeColor = Color(0xFF59CBEF);
  static const Color _inactiveColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Circles and Lines Row
        Row(
          children: [
            _buildStepCircle(1),
            _buildLine(1),
            _buildStepCircle(2),
            _buildLine(2),
            _buildStepCircle(3),
          ],
        ),
        const SizedBox(height: 8),
        // Labels Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel(1, 'Chọn xe và cửa hàng'),
            _buildLabel(2, 'Chọn thời gian'),
            _buildLabel(3, 'Chọn dịch vụ'),
          ],
        ),
      ],
    );
  }

  Widget _buildStepCircle(int step) {
    bool isCompleted = currentStep > step;
    bool isActive = currentStep == step;

    Color borderColor;
    Color backgroundColor;
    
    if (isCompleted) {
      // Step 1 status when at Step 2: COMPLETED -> Filled Blue, Border Blue
      borderColor = _activeColor;
      backgroundColor = _activeColor;
    } else if (isActive) {
      // Step 2 status when at Step 2: ACTIVE -> White bg, Blue Border
      borderColor = _activeColor;
      backgroundColor = Colors.white;
    } else {
      // Step 3 status when at Step 2: INACTIVE -> White bg, Black Border
      borderColor = _inactiveColor;
      backgroundColor = Colors.white;
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildLine(int stepIndex) {
    // Line connects stepIndex and stepIndex+1
    // Line 1 connects 1 -> 2.
    // If we are at Step 2 (currentStep=2), then Line 1 is completed/active connection.
    // Req: "Line giữa COMPLETED -> ACTIVE: màu xanh".
    // If Step 1 is Completed and Step 2 is Active => Line 1 connects them.
    // So if currentStep >= stepIndex + 1 (meaning we have reached next step), line is blue.
    // E.g. At Step 2: Line 1 (1->2) is Blue. Line 2 (2->3) is Black.
    // At Step 3: Line 1 (1->2) is Blue, Line 2 (2->3) is Blue.
    
    bool isColored = currentStep > stepIndex;

    return Expanded(
      child: Container(
        height: 1,
        color: isColored ? _activeColor : _inactiveColor,
      ),
    );
  }

  Widget _buildLabel(int step, String text) {
    bool isCompleted = currentStep > step;
    bool isActive = currentStep == step;

    Color color;
    FontWeight fontWeight;

    if (isCompleted) {
      // Step COMPLETED: Black, Bold
      color = _inactiveColor;
      fontWeight = FontWeight.bold;
    } else if (isActive) {
      // Step ACTIVE: Blue, Normal
      color = _activeColor;
      fontWeight = FontWeight.normal;
    } else {
      // Step INACTIVE: Black, Normal
      color = _inactiveColor;
      fontWeight = FontWeight.normal;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}
