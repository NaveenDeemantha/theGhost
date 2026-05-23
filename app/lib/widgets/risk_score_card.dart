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
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = Tween<double>(begin: 0, end: widget.result.score / 100)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(RiskScoreCard old) {
    super.didUpdateWidget(old);
    if (old.result.score != widget.result.score) {
      _anim = Tween<double>(
              begin: old.result.score / 100, end: widget.result.score / 100)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller..reset()..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _levelColor(RiskLevel l) {
    switch (l) {
      case RiskLevel.low:      return kGreen;
      case RiskLevel.medium:   return kCyan;
      case RiskLevel.high:     return kOrange;
      case RiskLevel.critical: return kRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(widget.result.level);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: kTerminalCard,
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: color.withAlpha(20),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded, size: 12, color: kGrayText),
                const SizedBox(width: 6),
                const Text('THREAT_ASSESSMENT.exe',
                    style: TextStyle(color: kGrayText, fontSize: 10,
                        fontFamily: 'monospace', letterSpacing: 1)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(border: Border.all(color: color)),
                  child: Text(
                    widget.result.level.label.toUpperCase(),
                    style: TextStyle(color: color, fontSize: 9,
                        fontFamily: 'monospace', fontWeight: FontWeight.bold,
                        letterSpacing: 1.5),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Arc gauge
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) {
                    final displayed = (widget.result.score * _anim.value).round();
                    return SizedBox(
                      width: 100,
                      height: 64,
                      child: CustomPaint(
                        painter: _ArcPainter(value: _anim.value, color: color),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text('$displayed',
                                style: TextStyle(
                                    color: color,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.result.factors.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('> ', style: TextStyle(color: color.withAlpha(150),
                              fontFamily: 'monospace', fontSize: 11)),
                          Expanded(
                            child: Text(f, style: const TextStyle(
                                color: kGrayText, fontFamily: 'monospace', fontSize: 11)),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value;
  final Color color;
  _ArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const sw = 8.0;
    final rect = Rect.fromLTWH(sw / 2, 0, size.width - sw, (size.height - sw) * 2);
    final trackPaint = Paint()
      ..color = kTerminalBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, pi, pi, false, trackPaint);
    if (value > 0) canvas.drawArc(rect, pi, pi * value, false, valuePaint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.value != value || old.color != color;
}
