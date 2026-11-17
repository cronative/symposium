import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// Welcome illustration (323×270): dashed radius rings, "You" in the centre,
/// three nearby-profession chips and a "128 professionals within 5 km" pill.
class NearbyVisual extends StatelessWidget {
  const NearbyVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 323,
      height: 270,
      decoration: BoxDecoration(
        gradient: AppGradients.welcomeVisual,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardStroke),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            const Positioned(left: 44, top: 7, child: _DashedRing(236, 0.30)),
            const Positioned(left: 78, top: 41, child: _DashedRing(168, 0.48)),
            const Positioned(left: 112, top: 75, child: _DashedRing(100, 0.72)),
            Positioned(
              left: 140,
              top: 103,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.auth,
                  boxShadow: [BoxShadow(color: AppColors.shadowBlue35, offset: Offset(0, 6), blurRadius: 14)],
                ),
                alignment: Alignment.center,
                child: const Text('You', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white)),
              ),
            ),
            const Positioned(left: 14, top: 16, child: _PersonChip('UI/UX Designer', '0.8 km away', AppColors.chipOrange)),
            const Positioned(left: 176, top: 58, child: _PersonChip('Startup Founder', '1.2 km away', AppColors.chipPurple)),
            const Positioned(left: 20, top: 168, child: _PersonChip('Marketing Lead', '2 km away', AppColors.chipGreen)),
            Positioned(
              left: 0,
              right: 0,
              top: 230,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(20)),
                  child: const Text(
                    '128 professionals within 5 km',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, height: 1.4, fontWeight: FontWeight.w600, color: AppColors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip(this.title, this.distance, this.dot);
  final String title;
  final String distance;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.shadowNavy12, offset: Offset(0, 4), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 18, height: 18, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, height: 1.3, fontWeight: FontWeight.w600, color: AppColors.navy)),
              Text(distance, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, height: 12 / 9, color: AppColors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashedRing extends StatelessWidget {
  const _DashedRing(this.size, this.opacity);
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) =>
      Opacity(opacity: opacity, child: CustomPaint(size: Size.square(size), painter: _DashPainter()));
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final r = size.width / 2 - 0.6;
    final c = Offset(size.width / 2, size.height / 2);
    const dash = 4.0;
    final circumference = 2 * math.pi * r;
    final count = (circumference / (dash * 2)).floor();
    final step = 2 * math.pi / count;
    final sweep = step / 2;
    for (var i = 0; i < count; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * step, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
