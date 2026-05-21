import 'dart:io';
import 'dart:async';
import '../models/network_device.dart';
import '../models/device_type.dart';

const _cameraOuis = {
  'b46780': 'Hikvision',
  'c0d0f8': 'Hikvision',
  '344b50': 'Hikvision',
  '283b82': 'Dahua',
  'e04f43': 'Dahua',
  '001d92': 'Axis',
  'accc8e': 'Axis',
  '00408c': 'Axis',
};

const _discoveryPorts = [80, 443, 554, 8080, 22, 8554, 37777];

const _classificationPorts = [
  554, 8554,
  37777, 34567,
  80, 443, 8080, 8443,
  9100, 631, 515,
  5000, 5001, 445,
  8008, 8009,
  22, 23,
];

class DeviceScanner {
  // Stream-based scan: emits each device as soon as it is classified
  static Stream<NetworkDevice> scanStream(
    String gatewayIp, {
    void Function(int scanned, int total)? onProgress,
  }) async* {
    final subnet = gatewayIp.substring(0, gatewayIp.lastIndexOf('.'));
    const total = 254;
    int scanned = 0;

    // Phase 1: discover alive hosts in large parallel batches
    const discoveryBatch = 50;
    final allIps = List.generate(total, (i) => '$subnet.${i + 1}');

    for (int i = 0; i < allIps.length; i += discoveryBatch) {
      final batch = allIps.skip(i).take(discoveryBatch).toList();
      final aliveResults = await Future.wait(batch.map(_isAlive));
      final aliveHosts = aliveResults.whereType<String>().toList();

      scanned += batch.length;
      onProgress?.call(scanned.clamp(0, total), total);

      // Phase 2: classify each alive host immediately and yield
      if (aliveHosts.isNotEmpty) {
        final classified = await Future.wait(aliveHosts.map(_classifyHost));
        for (final device in classified) {
          yield device;
        }
      }
    }
  }

  static Future<String?> _isAlive(String ip) async {
    for (final port in _discoveryPorts) {
      try {
        final s = await Socket.connect(ip, port,
            timeout: const Duration(milliseconds: 200));
        s.destroy();
        return ip;
      } catch (_) {}
    }
    return null;
  }

  static Future<NetworkDevice> _classifyHost(String ip) async {
    final openPorts = <int>[];

    await Future.wait(_classificationPorts.map((port) async {
      try {
        final s = await Socket.connect(ip, port,
            timeout: const Duration(milliseconds: 350));
        s.destroy();
        openPorts.add(port);
      } catch (_) {}
    }));

    final rtspPort =
        openPorts.firstWhere((p) => [554, 8554].contains(p), orElse: () => -1);
    final httpPort = openPorts.firstWhere(
        (p) => [80, 443, 8080, 8443].contains(p),
        orElse: () => -1);

    final hasRtsp = rtspPort != -1;
    final hasHttp = httpPort != -1;
    final hasCameraPort = openPorts.any((p) => [37777, 34567, 8554].contains(p));
    final hasPrinterPort = openPorts.any((p) => [9100, 631, 515].contains(p));
    final hasNasPort = openPorts.any((p) => [5000, 5001, 445].contains(p));
    final hasTvPort = openPorts.any((p) => [8008, 8009].contains(p));
    final hasSsh = openPorts.contains(22);
    final hasTelnet = openPorts.contains(23);

    bool isCamera = false;
    String? cameraConfidence;

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

    final deviceType = _classify(
      ip: ip,
      isCamera: isCamera,
      hasPrinterPort: hasPrinterPort,
      hasNasPort: hasNasPort,
      hasTvPort: hasTvPort,
      hasSsh: hasSsh,
      hasTelnet: hasTelnet,
      hasHttp: hasHttp,
      openPorts: openPorts,
    );

    String? hostname;
    try {
      final result = await InternetAddress(ip)
          .reverse()
          .timeout(const Duration(seconds: 1));
      hostname = result.host;
    } catch (_) {}

    return NetworkDevice(
      ipAddress: ip,
      hostname: hostname,
      manufacturer: _manufacturerFromMac(null),
      openPorts: openPorts,
      isCamera: isCamera,
      cameraConfidence: cameraConfidence,
      rtspPort: rtspPort != -1 ? rtspPort : null,
      httpPort: httpPort != -1 ? httpPort : null,
      deviceType: deviceType,
    );
  }

  static DeviceType _classify({
    required String ip,
    required bool isCamera,
    required bool hasPrinterPort,
    required bool hasNasPort,
    required bool hasTvPort,
    required bool hasSsh,
    required bool hasTelnet,
    required bool hasHttp,
    required List<int> openPorts,
  }) {
    if (isCamera) return DeviceType.camera;
    if (hasPrinterPort) return DeviceType.printer;
    if (hasNasPort) return DeviceType.nas;
    if (hasTvPort) return DeviceType.smartTv;
    final lastOctet = int.tryParse(ip.split('.').last) ?? 0;
    if ((lastOctet == 1 || lastOctet == 254) && (hasHttp || hasTelnet)) {
      return DeviceType.router;
    }
    if (hasSsh || openPorts.length > 3) return DeviceType.computer;
    if (openPorts.isNotEmpty) return DeviceType.iotDevice;
    return DeviceType.unknown;
  }

  static String? _manufacturerFromMac(String? mac) {
    if (mac == null) return null;
    final oui = mac.replaceAll(':', '').replaceAll('-', '').toLowerCase();
    if (oui.length < 6) return null;
    return _cameraOuis[oui.substring(0, 6)];
  }
}
