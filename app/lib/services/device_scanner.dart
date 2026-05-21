import 'dart:io';
import 'dart:async';
import '../models/network_device.dart';

// Camera OUI prefixes (first 6 hex chars of MAC, lowercase no colons)
const _cameraOuis = {
  'b46780': 'Hikvision',
  'c0d0f8': 'Hikvision',
  '344b50': 'Hikvision',
  '283b82': 'Dahua',
  'e04f43': 'Dahua',
  '001d92': 'Axis',
  'accc8e': 'Axis',
  '00408c': 'Axis',
  '000000': 'Unknown Camera',
};

// Ports commonly used by IP cameras
const _cameraPorts = [554, 8554, 80, 8080, 443, 8443, 37777, 34567];
const _rtspPorts = [554, 8554];
const _httpPorts = [80, 8080, 443, 8443];

class DeviceScanner {
  static Future<List<NetworkDevice>> scanSubnet(String gatewayIp) async {
    final subnet = gatewayIp.substring(0, gatewayIp.lastIndexOf('.'));
    final devices = <NetworkDevice>[];
    final futures = <Future<NetworkDevice?>>[];

    for (int i = 1; i <= 254; i++) {
      futures.add(_probeHost('$subnet.$i'));
    }

    // Run in batches of 30 to avoid overwhelming the network
    const batchSize = 30;
    for (int i = 0; i < futures.length; i += batchSize) {
      final batch = futures.skip(i).take(batchSize);
      final results = await Future.wait(batch);
      devices.addAll(results.whereType<NetworkDevice>());
    }

    return devices;
  }

  static Future<NetworkDevice?> _probeHost(String ip) async {
    try {
      final socket = await Socket.connect(ip, 80, timeout: const Duration(milliseconds: 300));
      socket.destroy();
      // Host responded on port 80 — probe it further
      return _scanDevice(ip);
    } catch (_) {
      // Try ICMP-style: attempt multiple ports quickly
      for (final port in [554, 8080, 443]) {
        try {
          final s = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 300));
          s.destroy();
          return _scanDevice(ip);
        } catch (_) {}
      }
      return null;
    }
  }

  static String? _manufacturerFromMac(String? mac) {
    if (mac == null) return null;
    final oui = mac.replaceAll(':', '').replaceAll('-', '').toLowerCase();
    if (oui.length < 6) return null;
    return _cameraOuis[oui.substring(0, 6)];
  }

  static Future<NetworkDevice> _scanDevice(String ip) async {
    final openPorts = <int>[];

    await Future.wait(_cameraPorts.map((port) async {
      try {
        final s = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 500));
        s.destroy();
        openPorts.add(port);
      } catch (_) {}
    }));

    final rtspPort = openPorts.firstWhere((p) => _rtspPorts.contains(p), orElse: () => -1);
    final httpPort = openPorts.firstWhere((p) => _httpPorts.contains(p), orElse: () => -1);

    String? manufacturer = _manufacturerFromMac(null);
    bool isCamera = false;
    String? cameraConfidence;

    final hasRtsp = rtspPort != -1;
    final hasHttp = httpPort != -1;
    final hasCameraPort = openPorts.any((p) => [37777, 34567, 8554].contains(p));

    if (hasRtsp && hasCameraPort) {
      isCamera = true;
      cameraConfidence = 'high';
    } else if (hasRtsp && hasHttp) {
      isCamera = true;
      cameraConfidence = 'medium';
    } else if (hasRtsp || hasCameraPort) {
      isCamera = true;
      cameraConfidence = 'low';
    }

    // Try to resolve hostname
    String? hostname;
    try {
      final result = await InternetAddress(ip).reverse().timeout(const Duration(seconds: 1));
      hostname = result.host;
    } catch (_) {}

    return NetworkDevice(
      ipAddress: ip,
      hostname: hostname,
      manufacturer: manufacturer,
      openPorts: openPorts,
      isCamera: isCamera,
      cameraConfidence: cameraConfidence,
      rtspPort: rtspPort != -1 ? rtspPort : null,
      httpPort: httpPort != -1 ? httpPort : null,
    );
  }
}
