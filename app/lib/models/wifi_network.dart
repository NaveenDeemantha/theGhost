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
}
