import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/motion_detection_service.dart';
import '../main.dart';

enum _Phase { idle, calibrating, monitoring }

class MotionRadarScreen extends StatefulWidget {
  const MotionRadarScreen({super.key});

  @override
  State<MotionRadarScreen> createState() => _MotionRadarScreenState();
}

class _MotionRadarScreenState extends State<MotionRadarScreen>
    with TickerProviderStateMixin {
  final _service = MotionDetectionService();
  _Phase _phase = _Phase.idle;
  MotionReading? _latest;
  final List<double> _history = [];
  StreamSubscription<MotionReading>? _sub;
  String? _error;
  int _calibrationStep = 0;
  int _scanCount = 0;
  DateTime? _lastScanTime;

  late final AnimationController _sweepCtrl;
  // Fires to 1.0 on every real scan arrival, then decays to 0.0 over 1.8 s.
  // This — not the sweep angle — controls blip brightness.
  late final AnimationController _pingCtrl;

  @override
  void initState() {
    super.initState();
    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    if (_service.hasBaseline) {
      _startMonitoring();
    }
  }

  @override
  void dispose() {
    _service.dispose();
    _sub?.cancel();
    _sweepCtrl.dispose();
    _pingCtrl.dispose();
    super.dispose();
  }

  Future<void> _calibrate() async {
    setState(() {
      _phase = _Phase.calibrating;
      _error = null;
      _calibrationStep = 0;
    });
    try {
      final count = await _service.calibrate(
        onStep: (s) { if (mounted) setState(() => _calibrationStep = s); },
      );
      if (!mounted) return;
      if (count == 0) {
        setState(() {
          _phase = _Phase.idle;
          _error = 'No WiFi APs found. Enable WiFi and grant location permission.';
        });
      } else {
        _startMonitoring();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _phase = _Phase.idle; _error = e.toString(); });
    }
  }

  void _startMonitoring() {
    _sub?.cancel();
    _sub = _service.readings.listen((reading) {
      if (!mounted) return;
      // Flash blips to full brightness on every real scan arrival, then decay.
      _pingCtrl.reverse(from: 1.0);
      setState(() {
        _latest = reading;
        _scanCount++;
        _lastScanTime = DateTime.now();
        _history.add(reading.motionScore);
        if (_history.length > 50) _history.removeAt(0);
      });
    });
    _service.startMonitoring();
    setState(() => _phase = _Phase.monitoring);
  }

  void _stop() {
    _service.stopMonitoring();
    _sub?.cancel();
    _pingCtrl.stop();
    setState(() {
      _phase = _Phase.idle;
      _latest = null;
      _history.clear();
      _scanCount = 0;
      _lastScanTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final score = _latest?.motionScore ?? 0.0;
    final isDetected = score >= 50;
    final isMaybe = score >= 25 && score < 50;

    return Scaffold(
      backgroundColor: kTerminalBg,
      appBar: AppBar(
        title: const Text('WIFI MOTION RADAR'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kGreenDim.withAlpha(80)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Radar ───────────────────────────────────────────────────────
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_sweepCtrl, _pingCtrl]),
                builder: (_, __) => CustomPaint(
                  size: const Size(270, 270),
                  painter: _RadarPainter(
                    sweepFraction: _sweepCtrl.value,
                    pingValue: _pingCtrl.value,
                    blips: _latest?.blips ?? [],
                    active: _phase == _Phase.monitoring,
                    motionScore: score,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Status card ─────────────────────────────────────────────────
            _buildStatus(score, isDetected, isMaybe),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: kRed),
                  color: kRed.withAlpha(15),
                ),
                child: Text('! $_error',
                    style: const TextStyle(
                        color: kRed, fontFamily: 'monospace', fontSize: 11)),
              ),
            ],

            // ── Signal history graph ─────────────────────────────────────────
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildGraph(),
            ],

            // ── Sensor list ─────────────────────────────────────────────────
            if (_latest != null && _latest!.deltas.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSensorList(),
            ],

            // ── Sensitivity ─────────────────────────────────────────────────
            const SizedBox(height: 16),
            _buildSensitivity(),

            // ── Buttons ─────────────────────────────────────────────────────
            const SizedBox(height: 12),
            _buildButtons(),

            // ── Info box ────────────────────────────────────────────────────
            const SizedBox(height: 16),
            _buildInfoBox(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Sub-builders ────────────────────────────────────────────────────────────

  Widget _buildStatus(double score, bool isDetected, bool isMaybe) {
    final Color color;
    final String title;
    final String sub;

    if (_phase == _Phase.idle) {
      color = kDimText;
      title = 'STANDBY';
      sub = 'Tap CALIBRATE — keep device still during calibration';
    } else if (_phase == _Phase.calibrating) {
      color = kCyan;
      title = 'CALIBRATING...';
      sub = 'Scan $_calibrationStep / 5  •  Do not move the device';
    } else if (isDetected) {
      color = kRed;
      title = 'MOTION DETECTED';
      sub = 'Significant signal disturbance across ${_latest!.activeSensors} sensors';
    } else if (isMaybe) {
      color = kOrange;
      title = 'POSSIBLE MOVEMENT';
      sub = 'Low-level signal variation detected';
    } else {
      color = kGreen;
      title = 'AREA CLEAR';
      sub = 'No significant motion — ${_latest?.activeSensors ?? 0} sensors active';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(120)),
        color: color.withAlpha(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                    color: color,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 2,
                  )),
              const Spacer(),
              if (_phase == _Phase.monitoring)
                Text('${score.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: color,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    )),
            ],
          ),
          const SizedBox(height: 6),
          Text(sub,
              style: const TextStyle(
                  color: kGrayText, fontFamily: 'monospace', fontSize: 11)),
          if (_phase == _Phase.monitoring) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: kTerminalBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoChip(
                  label: 'SCAN #$_scanCount',
                  color: kGrayText,
                ),
                const SizedBox(width: 8),
                if (_lastScanTime != null)
                  _InfoChip(
                    label: 'LAST: ${DateTime.now().difference(_lastScanTime!).inSeconds}s ago',
                    color: kGrayText,
                  ),
                const SizedBox(width: 8),
                _InfoChip(
                  label: '${_latest?.activeSensors ?? 0} APs',
                  color: kCyan,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGraph() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SIGNAL VARIANCE HISTORY',
            style: TextStyle(
                color: kGrayText, fontFamily: 'monospace',
                fontSize: 9, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Container(
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(color: kTerminalBorder),
            color: kTerminalCard,
          ),
          child: CustomPaint(
            painter: _GraphPainter(history: List.unmodifiable(_history)),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorList() {
    final sorted = _latest!.deltas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AP SENSORS [${_latest!.activeSensors} active]',
            style: const TextStyle(
                color: kGrayText, fontFamily: 'monospace',
                fontSize: 9, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: kTerminalBorder),
            color: kTerminalCard,
          ),
          child: Column(
            children: top.asMap().entries.map((entry) {
              final idx = entry.key;
              final e = entry.value;
              final blip = _latest!.blips.where((b) => b.bssid == e.key).firstOrNull;
              final ssid = (blip?.ssid.isNotEmpty == true) ? blip!.ssid : e.key;
              final frac = (e.value / 15.0).clamp(0.0, 1.0);
              final barColor = e.value >= 8 ? kRed
                  : e.value >= 4 ? kOrange
                  : kGreenDim;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  border: idx < top.length - 1
                      ? const Border(bottom: BorderSide(color: kTerminalBorder))
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ssid.isEmpty ? '[HIDDEN]' : ssid,
                        style: const TextStyle(
                            color: kWhiteText, fontFamily: 'monospace', fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 60,
                      height: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(1),
                        child: LinearProgressIndicator(
                          value: frac,
                          backgroundColor: kTerminalBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('+${e.value}dBm',
                        style: TextStyle(
                            color: barColor,
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSensitivity() {
    const labels = {
      MotionSensitivity.low: 'LOW',
      MotionSensitivity.medium: 'MEDIUM',
      MotionSensitivity.high: 'HIGH',
    };
    const hints = {
      MotionSensitivity.low: '>8dBm',
      MotionSensitivity.medium: '>4dBm',
      MotionSensitivity.high: '>2dBm',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SENSITIVITY',
            style: TextStyle(
                color: kGrayText, fontFamily: 'monospace',
                fontSize: 9, letterSpacing: 1.5)),
        const SizedBox(height: 6),
        Row(
          children: MotionSensitivity.values.map((s) {
            final sel = _service.sensitivity == s;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _service.sensitivity = s),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? kGreenFaint : kTerminalCard,
                    border: Border.all(color: sel ? kGreen : kTerminalBorder),
                  ),
                  child: Column(
                    children: [
                      Text(labels[s]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: sel ? kGreen : kGrayText,
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                            letterSpacing: 1,
                          )),
                      Text(hints[s]!,
                          style: TextStyle(
                              color: sel ? kGreenDim : kDimText,
                              fontFamily: 'monospace',
                              fontSize: 8)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _phase == _Phase.calibrating ? null : _calibrate,
            icon: Icon(
              _phase == _Phase.calibrating
                  ? Icons.hourglass_bottom_rounded
                  : Icons.tune_rounded,
              size: 16,
            ),
            label: Text(
              _phase == _Phase.calibrating
                  ? 'CALIBRATING $_calibrationStep/5...'
                  : 'CALIBRATE',
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (_phase == _Phase.monitoring)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _stop,
              icon: const Icon(Icons.stop_rounded, size: 16),
              label: const Text('STOP'),
            ),
          )
        else if (_service.hasBaseline && _phase == _Phase.idle)
          Expanded(
            child: FilledButton.icon(
              onPressed: _startMonitoring,
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text('RESUME'),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: kTerminalBorder),
        color: kTerminalCard,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOW IT WORKS',
              style: TextStyle(
                  color: kGreen, fontFamily: 'monospace',
                  fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            '1. CALIBRATE  —  records baseline RSSI for every visible WiFi access point. Keep device still.\n\n'
            '2. MONITOR  —  scans every 2 s. Moving objects disturb WiFi multipath propagation, causing correlated RSSI shifts across multiple APs.\n\n'
            '3. SCORE  —  average delta of the 5 most-changed APs, normalised to 0–100%. Higher = more disturbance.\n\n'
            'Accuracy increases with more visible APs (5+). Android throttles scans to ~1 per 2 s.',
            style: TextStyle(
                color: kGrayText, fontFamily: 'monospace',
                fontSize: 10, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ── Radar painter ──────────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final double sweepFraction; // 0.0 → 1.0 — purely cosmetic rotation
  final double pingValue;     // 1.0 = scan just arrived, 0.0 = stale — drives blip brightness
  final List<ApBlip> blips;
  final bool active;
  final double motionScore;

  const _RadarPainter({
    required this.sweepFraction,
    required this.pingValue,
    required this.blips,
    required this.active,
    required this.motionScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    // sweepAngle: 0 = top, clockwise
    final sweepAngle = sweepFraction * 2 * pi;

    // 1. Concentric range rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      ringPaint.color = kGreenDim.withAlpha(active ? 55 : 25);
      canvas.drawCircle(center, radius * i / 3, ringPaint);
    }

    // 2. Cross-hairs
    final crossPaint = Paint()
      ..color = kGreenDim.withAlpha(active ? 35 : 15)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), crossPaint);

    // 3. Outer ring
    ringPaint.color = kGreen.withAlpha(active ? 90 : 35);
    canvas.drawCircle(center, radius, ringPaint);

    if (!active) {
      // Inactive indicator
      final p = Paint()..color = kDimText..strokeWidth = 2;
      canvas.drawLine(Offset(center.dx - 12, center.dy),
          Offset(center.dx + 12, center.dy), p);
      canvas.drawLine(Offset(center.dx, center.dy - 12),
          Offset(center.dx, center.dy + 12), p);
      return;
    }

    // 4. Sweep sector — trailing glow (quadratic falloff)
    const trailArc = pi / 2; // 90-degree trail
    const steps = 32;
    for (int i = 0; i < steps; i++) {
      final t = 1.0 - i / steps;
      final startA = (sweepAngle - trailArc * (i + 1) / steps) - pi / 2;
      final sweepA = trailArc / steps;
      final alpha = (t * t * 70).round();
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startA,
        sweepA,
        true,
        Paint()..color = kGreen.withAlpha(alpha),
      );
    }

    // 5. Sweep line
    final sweepRad = sweepAngle - pi / 2;
    canvas.drawLine(
      center,
      Offset(center.dx + radius * cos(sweepRad), center.dy + radius * sin(sweepRad)),
      Paint()..color = kGreen.withAlpha(200)..strokeWidth = 2,
    );

    // 6. Center dot — intensity scales with motion score
    canvas.drawCircle(
      center, 4,
      Paint()..color = kGreen.withAlpha((100 + motionScore * 1.55).round()),
    );

    // 7. AP blips — driven by real scan data, not the sweep animation.
    // pingValue = 1.0 immediately after a scan arrives, decays to 0.0 over 1.8 s.
    // Base brightness (0.15) keeps blips dimly visible between scans so the
    // user can see the AP positions at all times.
    for (final blip in blips) {
      final blipAngle = blip.angle - pi / 2;
      final blipPos = Offset(
        center.dx + radius * blip.distFraction * cos(blipAngle),
        center.dy + radius * blip.distFraction * sin(blipAngle),
      );

      final freshness = 0.15 + 0.85 * pingValue; // 0.15 base → 1.0 on fresh scan
      final intensity = (blip.delta / 12.0).clamp(0.0, 1.0);
      final alpha = (freshness * intensity * 230).round();

      if (alpha > 8) {
        final dotColor = blip.delta >= 10 ? kRed
            : blip.delta >= 5 ? kOrange
            : kGreen;
        canvas.drawCircle(blipPos, 9, Paint()..color = dotColor.withAlpha(alpha ~/ 5));
        canvas.drawCircle(blipPos, 3, Paint()..color = dotColor.withAlpha(alpha));
      }
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      sweepFraction != old.sweepFraction ||
      pingValue != old.pingValue ||
      blips != old.blips ||
      active != old.active ||
      motionScore != old.motionScore;
}

// ── Small label chip ─────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: color.withAlpha(80))),
      child: Text(label,
          style: TextStyle(
              color: color, fontFamily: 'monospace', fontSize: 9, letterSpacing: 0.5)),
    );
  }
}

// ── Signal history graph ──────────────────────────────────────────────────────

class _GraphPainter extends CustomPainter {
  final List<double> history;
  const _GraphPainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    final barW = size.width / history.length;

    // Bars
    for (int i = 0; i < history.length; i++) {
      final score = history[i];
      final barH = (score / 100) * size.height;
      final color = score >= 50 ? kRed : score >= 25 ? kOrange : kGreenDim;
      canvas.drawRect(
        Rect.fromLTWH(i * barW, size.height - barH, max(barW - 1, 1), barH),
        Paint()..color = color.withAlpha(180),
      );
    }

    // Dashed 50% threshold line
    const dashW = 4.0;
    const dashGap = 4.0;
    final threshY = size.height * 0.5;
    final dashPaint = Paint()..color = kRed.withAlpha(70)..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, threshY), Offset(x + dashW, threshY), dashPaint);
      x += dashW + dashGap;
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) => history != old.history;
}
