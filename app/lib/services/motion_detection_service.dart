import 'dart:async';
import 'dart:math';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';

enum MotionSensitivity { low, medium, high }

class ApBlip {
  final String bssid;
  final String ssid;
  final int delta;        // dBm deviation from baseline (motion contribution)
  final int rssi;         // actual current RSSI (used to compute display distance)
  final double angle;     // 0..2π clockwise from top — fixed per BSSID (hash-derived)
  final double distFraction; // 0.0 (center) .. 1.0 (edge), derived from real RSSI

  const ApBlip({
    required this.bssid,
    required this.ssid,
    required this.delta,
    required this.rssi,
    required this.angle,
    required this.distFraction,
  });
}

class MotionReading {
  final DateTime timestamp;
  final double motionScore; // 0–100
  final int activeSensors;
  final List<ApBlip> blips;
  final Map<String, int> deltas; // bssid → |current - baseline| dBm

  const MotionReading({
    required this.timestamp,
    required this.motionScore,
    required this.activeSensors,
    required this.blips,
    required this.deltas,
  });
}

class MotionDetectionService {
  // Static baseline so calibration survives screen navigation
  static Map<String, double> _baseline = {};
  static final Map<String, String> _bssidSsid = {};

  final StreamController<MotionReading> _controller =
      StreamController<MotionReading>.broadcast();
  Timer? _timer;
  MotionSensitivity sensitivity = MotionSensitivity.medium;

  Stream<MotionReading> get readings => _controller.stream;
  bool get hasBaseline => _baseline.isNotEmpty;
  int get baselineApCount => _baseline.length;

  // dBm average-delta threshold at which score hits ~30%
  double get _threshold {
    switch (sensitivity) {
      case MotionSensitivity.low:
        return 8.0;
      case MotionSensitivity.medium:
        return 4.0;
      case MotionSensitivity.high:
        return 2.0;
    }
  }

  /// Calibrate baseline over [scans] WiFi scans (~1.5 s each).
  /// [onStep] is called after each scan with the current step number (1-based).
  Future<int> calibrate({int scans = 5, void Function(int step)? onStep}) async {
    await Permission.location.request();
    _baseline.clear();
    _bssidSsid.clear();

    final Map<String, List<int>> readings = {};

    for (int i = 0; i < scans; i++) {
      final can = await WiFiScan.instance.canStartScan(askPermissions: true);
      if (can == CanStartScan.yes) await WiFiScan.instance.startScan();
      await Future.delayed(const Duration(milliseconds: 1500));
      final results = await WiFiScan.instance.getScannedResults();
      for (final ap in results) {
        readings.putIfAbsent(ap.bssid, () => []).add(ap.level);
        _bssidSsid[ap.bssid] = ap.ssid;
      }
      onStep?.call(i + 1);
    }

    _baseline = readings.map((bssid, levels) {
      final avg = levels.reduce((a, b) => a + b) / levels.length;
      return MapEntry(bssid, avg);
    });

    return _baseline.length;
  }

  void startMonitoring() {
    _timer?.cancel();
    _doScan();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _doScan());
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _doScan() async {
    if (_baseline.isEmpty || _controller.isClosed) return;

    final can = await WiFiScan.instance.canStartScan();
    if (can == CanStartScan.yes) await WiFiScan.instance.startScan();
    final results = await WiFiScan.instance.getScannedResults();

    final Map<String, int> deltas = {};
    for (final ap in results) {
      final base = _baseline[ap.bssid];
      if (base != null) {
        deltas[ap.bssid] = (ap.level - base).abs().round();
      }
    }

    if (deltas.isEmpty) return;

    // Average of top-5 AP deltas → more robust than single-AP measurement
    final sortedDeltas = deltas.values.toList()..sort((a, b) => b.compareTo(a));
    final topCount = min(sortedDeltas.length, 5);
    final avgDelta =
        sortedDeltas.take(topCount).reduce((a, b) => a + b) / topCount;

    // Score: 0 at rest, 100 at 3× threshold. Clamped to [0, 100].
    final motionScore = ((avgDelta / (_threshold * 3)) * 100).clamp(0.0, 100.0);

    // Build a BSSID→RSSI lookup from this scan so blips use real signal levels
    final rssiMap = <String, int>{
      for (final ap in results) ap.bssid: ap.level,
    };

    // Blip positions: angle is hash-fixed per AP (we can't know direction),
    // distFraction is derived from real RSSI so closer routers sit near center.
    // Log-distance path-loss: d = 10^((txPower - rssi) / (10*n))
    // Normalise to 0.08–0.92 using a 50 m max range reference.
    final blips = deltas.entries.map((e) {
      final hash = e.key.hashCode.abs();
      final rssi = rssiMap[e.key] ?? -80;
      final distM = pow(10.0, (-59.0 - rssi) / 27.0); // 2.4 GHz approx
      final distFraction = (distM / 50.0).clamp(0.08, 0.92).toDouble();
      return ApBlip(
        bssid: e.key,
        ssid: _bssidSsid[e.key] ?? '',
        delta: e.value,
        rssi: rssi,
        angle: (hash % 360) * (pi / 180),
        distFraction: distFraction,
      );
    }).toList();

    _controller.add(MotionReading(
      timestamp: DateTime.now(),
      motionScore: motionScore,
      activeSensors: deltas.length,
      blips: blips,
      deltas: deltas,
    ));
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}
