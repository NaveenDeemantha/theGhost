import '../models/network_device.dart';

enum RiskLevel { low, medium, high, critical }

class RiskResult {
  final int score;
  final RiskLevel level;
  final List<String> factors;

  RiskResult({required this.score, required this.level, required this.factors});
}

class RiskScoreService {
  static RiskResult calculate({
    required String encryption,
    required List<NetworkDevice> devices,
  }) {
    int score = 0;
    final factors = <String>[];

    // Encryption risk
    switch (encryption.toUpperCase()) {
      case 'OPEN':
        score += 40;
        factors.add('Network has no encryption (Open)');
        break;
      case 'WEP':
        score += 30;
        factors.add('WEP encryption is easily cracked');
        break;
      case 'WPA':
        score += 15;
        factors.add('WPA (original) has known vulnerabilities');
        break;
      case 'WPA2':
        score += 5;
        factors.add('WPA2 is generally secure');
        break;
      case 'WPA3':
        factors.add('WPA3 — strong encryption');
        break;
      default:
        score += 5;
    }

    // Camera risk
    final cameras = devices.where((d) => d.isCamera).length;
    if (cameras > 0) {
      final cameraScore = (cameras * 15).clamp(0, 45);
      score += cameraScore;
      factors.add('$cameras CCTV camera${cameras > 1 ? "s" : ""} detected');
    }

    // Unknown device risk
    final unknownCount = devices.where((d) => d.manufacturer == null && !d.isCamera).length;
    if (unknownCount > 0) {
      final unknownScore = (unknownCount * 2).clamp(0, 20);
      score += unknownScore;
      factors.add('$unknownCount unidentified device${unknownCount > 1 ? "s" : ""} on network');
    }

    // Large network risk
    if (devices.length > 15) {
      score += 10;
      factors.add('${devices.length} devices on network — large attack surface');
    }

    // IoT device risk
    final iotCount = devices.where((d) =>
        d.deviceType.name == 'iotDevice').length;
    if (iotCount > 2) {
      score += 8;
      factors.add('$iotCount IoT devices detected — potential weak points');
    }

    score = score.clamp(0, 100);

    RiskLevel level;
    if (score <= 25) {
      level = RiskLevel.low;
    } else if (score <= 50) {
      level = RiskLevel.medium;
    } else if (score <= 75) {
      level = RiskLevel.high;
    } else {
      level = RiskLevel.critical;
    }

    return RiskResult(score: score, level: level, factors: factors);
  }

  static RiskResult fromEncryptionOnly(String encryption) {
    return calculate(encryption: encryption, devices: []);
  }
}

extension RiskLevelExtension on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.critical:
        return 'Critical Risk';
    }
  }

  int get color {
    switch (this) {
      case RiskLevel.low:
        return 0xFF4CAF50;
      case RiskLevel.medium:
        return 0xFFFF9800;
      case RiskLevel.high:
        return 0xFFF44336;
      case RiskLevel.critical:
        return 0xFF880E4F;
    }
  }
}
