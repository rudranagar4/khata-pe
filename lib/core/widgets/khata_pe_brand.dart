import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class KhataPeBrand extends StatelessWidget {
  final double fontSize;
  final double iconSize;

  const KhataPeBrand({
    super.key,
    this.fontSize = 24,
    this.iconSize = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Khata Pe App Logo
        ClipRRect(
          borderRadius: BorderRadius.circular(iconSize * 0.22),
          child: Image.asset(
            'assets/images/logo.png',
            width: iconSize,
            height: iconSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(5),
              child: CustomPaint(
                painter: _LedgerIconPainter(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
            children: const [
              TextSpan(
                text: 'Khata ',
                style: TextStyle(color: Colors.white),
              ),
              TextSpan(
                text: 'Pe',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LedgerIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final bgPaint = Paint()
      ..color = const Color(0xFF0F5132)
      ..style = PaintingStyle.fill;

    // Inner paper shape
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, bgPaint);

    // Ledger horizontal lines
    final startX = 6.0;
    final endX = size.width - 6.0;
    canvas.drawLine(Offset(startX, size.height * 0.35), Offset(endX, size.height * 0.35), linePaint);
    canvas.drawLine(Offset(startX, size.height * 0.55), Offset(endX, size.height * 0.55), linePaint);
    canvas.drawLine(Offset(startX, size.height * 0.75), Offset(startX + (endX - startX) * 0.6, size.height * 0.75), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CircularTopActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool hasBadge;
  final Color? iconColor;

  const CircularTopActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.hasBadge = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.iconButtonDark,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: 21,
              color: iconColor ?? Colors.white.withOpacity(0.9),
            ),
            if (hasBadge)
              Positioned(
                top: 10,
                right: 11,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444), // Red badge dot
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

