import 'dart:math';
import 'package:flutter/material.dart';
import '../services/risk_score_service.dart';
import '../main.dart';

class RiskScoreCard extends StatefulWidget {
  final RiskResult result;
  const RiskScoreCard({super.key, required this.result});

  @override
  State<RiskScoreCard> createState() => _RiskScoreCardState();
}

class _RiskScoreCardState extends State<RiskScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _scoreAnim = Tween<double>(begin: 0, end: widget.result.score / 100)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(RiskScoreCard old) {
    super.didUpdateWidget(old);
    if (old.result.score != widget.result.score) {
      _scoreAnim = Tween<double>(
              begin: old.result.score / 100,
              end: widget.result.score / 100)
          .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.result.level.color);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: kNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.shield, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Text('Network Risk Assessment',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: kOffWhite, letterSpacing: 0.3)),
                const Spacer(),
                _LevelBadge(level: widget.result.level, color: color),
              ],
            ),
            const SizedBox(height: 20),

            // Gauge + factors row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Arc gauge
                AnimatedBuilder(
                  animation: _scoreAnim,
                  builder: (_, __) => SizedBox(
                    width: 110,
                    height: 70,
                    child: CustomPaint(
                      painter: _ArcGaugePainter(
                        value: _scoreAnim.value,
                        color: color,
                        trackColor: kNavyLight,
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${(widget.result.score * _scoreAnim.value / (widget.result.score / 100)).round()}',
                            style: TextStyle(
                              color: color,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Factors
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.result.factors
                        .map((f) => _FactorRow(text: f, color: color))
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color trackColor;

  _ArcGaugePainter(
      {required this.value, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final rect = Rect.fromLTWH(
        strokeWidth / 2, 0, size.width - strokeWidth, size.height * 2 - strokeWidth);
    const startAngle = pi;
    const sweepAngle = pi;

    // Track
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Value arc
    if (value > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle * value,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    // Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final entry in {'0': 0.0, '100': 1.0}.entries) {
      textPainter.text = TextSpan(
        text: entry.key,
        style: TextStyle(color: trackColor, fontSize: 10),
      );
      textPainter.layout();
      final angle = startAngle + sweepAngle * entry.value;
      final r = size.width / 2 - strokeWidth * 1.8;
      final cx = size.width / 2 + r * cos(angle) - textPainter.width / 2;
      final cy = size.height + r * sin(angle) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(cx, cy));
    }
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) =>
      old.value != value || old.color != color;
}

class _LevelBadge extends StatelessWidget {
  final RiskLevel level;
  final Color color;
  const _LevelBadge({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        level.label.toUpperCase(),
        style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 0.8),
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  final String text;
  final Color color;
  const _FactorRow({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Color(0xFF8AAAD4), fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
