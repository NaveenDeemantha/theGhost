import 'dart:math';

class WifiNetwork {
  final String ssid;
  final String bssid;
  final int signalStrength;
  final String encryption;
  final int frequency;
  final bool isConnected;
  final bool hasWps;

  WifiNetwork({
    required this.ssid,
    required this.bssid,
    required this.signalStrength,
    required this.encryption,
    required this.frequency,
    this.isConnected = false,
    this.hasWps = false,
  });

  Map<String, dynamic> toJson() => {
        'ssid': ssid,
        'bssid': bssid,
        'signalStrength': signalStrength,
        'encryption': encryption,
        'frequency': frequency,
      };

  bool get isOpen => encryption == 'Open';

  String get signalLabel {
    if (signalStrength >= -50) return 'Excellent';
    if (signalStrength >= -65) return 'Good';
    if (signalStrength >= -75) return 'Fair';
    return 'Weak';
  }

  int get signalBars {
    if (signalStrength >= -50) return 4;
    if (signalStrength >= -65) return 3;
    if (signalStrength >= -75) return 2;
    return 1;
  }

  // Convert frequency (MHz) to WiFi channel number
  int get channel {
    if (frequency <= 0) return 0;
    if (frequency >= 5000) return (frequency - 5000) ~/ 5;
    if (frequency == 2484) return 14;
    return (frequency - 2412) ~/ 5 + 1;
  }

  // Log-Distance Path Loss Model:  distance = 10 ^ ((txPower - RSSI) / (10 * n))
  // txPower: reference RSSI at 1m (-59 dBm for 2.4GHz, -65 dBm for 5GHz)
  // n: path-loss exponent (2.7 indoor 2.4GHz, 3.5 indoor 5GHz)
  double get estimatedDistanceMeters {
    final txPower = frequency >= 5000 ? -65.0 : -59.0;
    final n = frequency >= 5000 ? 3.5 : 2.7;
    if (signalStrength >= txPower) return 1.0;
    return pow(10.0, (txPower - signalStrength) / (10.0 * n)).toDouble();
  }

  String get distanceLabel {
    final d = estimatedDistanceMeters;
    if (d < 1.5) return '<1m';
    if (d < 10) return '~${d.toStringAsFixed(1)}m';
    if (d < 100) return '~${d.toStringAsFixed(0)}m';
    return '>100m';
  }
}
