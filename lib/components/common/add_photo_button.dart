import 'package:flutter/material.dart';
import 'dart:math' as math;

class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DottedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dashWidth = 4.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Calculate the circumference
    final circumference = 2 * math.pi * radius;
    
    // Calculate how many dashes we can fit
    final dashLength = dashWidth + dashSpace;
    final numberOfDashes = (circumference / dashLength).floor();
    
    // Calculate the angle for each dash
    final angleStep = 2 * math.pi / numberOfDashes;
    
    for (int i = 0; i < numberOfDashes; i++) {
      final startAngle = i * angleStep;
      final endAngle = startAngle + (dashWidth / radius);
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AddPhotoButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final String? ariaLabel;

  const AddPhotoButton({
    super.key,
    this.onPressed,
    this.size = 128.0, // 32 * 4 = 128 (32 * 4 for Flutter's logical pixels)
    this.ariaLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: CustomPaint(
        painter: DottedBorderPainter(
          color: const Color(0xFFFB923C), // orange-400
          strokeWidth: 2.0,
          dashWidth: 6.0,
          dashSpace: 4.0,
        ),
        child: Container(
          width: size,
          height: size,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(size / 2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: size * 0.625, // 20/32 = 0.625
                    height: size * 0.625,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFED7AA), // orange-100
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '+',
                        style: TextStyle(
                          color: Color(0xFFEA580C), // orange-600
                          fontSize: 48, // text-5xl equivalent
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
