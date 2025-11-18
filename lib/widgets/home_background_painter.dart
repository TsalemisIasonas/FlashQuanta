import 'package:flutter/material.dart';

class HomeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBlue = Paint()
      ..color = const Color(0xFF145C96).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final paintOrange = Paint()
      ..color = const Color(0xFFFF9800).withOpacity(0.45)
      ..style = PaintingStyle.fill;

    // Large blue wave mirroring the orange wave vertically, very low and smooth
    final pathBlue = Path()
      ..moveTo(size.width * -0.1, size.height * 0.9)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.87,
        size.width * 0.75,
        size.height * 0.93,
      )
      ..quadraticBezierTo(
        size.width * 1.05,
        size.height * 0.95,
        size.width * 1.2,
        size.height * 0.97,
      )
      ..lineTo(size.width * 1.2, size.height + 40)
      ..lineTo(-40, size.height + 40)
      ..close();

    // Bottom orange accent wave: flipped version of the original top curve
    // Slightly lowered so its highest points sit a bit closer to the bottom
    final pathOrangeBottom = Path()
      ..moveTo(size.width * -0.1, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.88,
        size.width * 0.9,
        size.height * 0.8,
      )
      ..quadraticBezierTo(
        size.width * 1.5,
        size.height * 0.65,
        size.width * 1.05,
        size.height * 0.83,
      )
      ..lineTo(size.width * 1.2, size.height + 40)
      ..lineTo(-40, size.height + 40)
      ..close();

    // Draw orange first, then blue on top so blue stays visually dominant
    canvas.drawPath(pathOrangeBottom, paintOrange);
    canvas.drawPath(pathBlue, paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
