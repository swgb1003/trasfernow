import 'package:flutter/material.dart';

/// Circular "成立可能性" gauge. See SPEC.md §9 / §22 (animates 0% → value).
class ProbabilityGauge extends StatelessWidget {
  const ProbabilityGauge({
    super.key,
    required this.probability,
    required this.color,
    this.size = 160,
    this.strokeWidth = 12,
  });

  final int probability;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: probability / 100),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: strokeWidth,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: TextStyle(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const Text(
                    '成立可能性',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
