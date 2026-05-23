import 'package:wifi_scan/wifi_scan.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_iot/wifi_iot.dart' hide WifiNetwork;
import 'package:permission_handler/permission_handler.dart';
import '../models/wifi_network.dart';

class WifiService {
  static final _networkInfo = NetworkInfo();

  // Returns cached scan results (no startScan — very fast).
  // Shows something immediately on first load while the full scan runs.
  static Future<List<WifiNetwork>> getCachedNetworks() async {
    final status = await Permission.location.status;
    if (!status.isGranted) return [];
    final can = await WiFiScan.instance.canGetScannedResults(askPermissions: false);
    if (can != CanGetScannedResults.yes) return [];
    final results = await WiFiScan.instance.getScannedResults();
    return _parseAps(results);
  }

  // Triggers a fresh scan then returns the results.
  static Future<List<WifiNetwork>> scanNearbyNetworks() async {
    final status = await Permission.location.status;
    if (!status.isGranted) await Permission.location.request();

    final canScan = await WiFiScan.instance.canStartScan(askPermissions: true);
    if (canScan == CanStartScan.yes) await WiFiScan.instance.startScan();

    final canRead = await WiFiScan.instance.canGetScannedResults(askPermissions: true);
    if (canRead != CanGetScannedResults.yes) return [];

    final results = await WiFiScan.instance.getScannedResults();
    return _parseAps(results);
  }

  // Parallelise all five NetworkInfo calls so the connected card appears fast.
  static Future<Map<String, String?>> getConnectedNetworkInfo() async {
    final status = await Permission.location.status;
    if (!status.isGranted) await Permission.location.request();

    final parts = await Future.wait([
      _networkInfo.getWifiName(),
      _networkInfo.getWifiBSSID(),
      _networkInfo.getWifiIP(),
      _networkInfo.getWifiGatewayIP(),
      _networkInfo.getWifiSubmask(),
    ]);

    var ssid    = parts[0]?.replaceAll('"', '').trim();
    final bssid  = parts[1];
    final ip     = parts[2];
    var gateway  = parts[3];
    final subnet = parts[4];

    if (ssid == null || ssid.isEmpty || ssid == '<unknown ssid>') ssid = null;

    if ((gateway == null || gateway.isEmpty) && ip != null && ip.isNotEmpty) {
      final segs = ip.split('.');
      if (segs.length == 4) gateway = '${segs[0]}.${segs[1]}.${segs[2]}.1';
    }

    return {
      'ssid': ssid, 'bssid': bssid,
      'ip': ip,     'gateway': gateway, 'subnet': subnet,
    };
  }

  static Future<WifiConnectionResult> connectToNetwork({
    required String ssid,
    required String encryption,
    String? password,
  }) async {
    try {
      final isOpen = encryption == 'Open';
      final security = isOpen ? NetworkSecurity.NONE
          : encryption == 'WEP' ? NetworkSecurity.WEP
          : NetworkSecurity.WPA;

      final success = await WiFiForIoTPlugin.connect(
        ssid,
        password: isOpen ? null : password,
        security: security,
        joinOnce: false,
        withInternet: true,
      ).timeout(const Duration(seconds: 15));

      return success ? WifiConnectionResult.success : WifiConnectionResult.failed;
    } catch (_) {
      return WifiConnectionResult.error;
    }
  }

  static Future<void> disconnect() => WiFiForIoTPlugin.disconnect();

  // ── Private helpers ────────────────────────────────────────────────────────

  static List<WifiNetwork> _parseAps(List<WiFiAccessPoint> aps) {
    return aps.map((ap) {
      final caps = ap.capabilities;
      final encryption = caps.contains('WPA3') ? 'WPA3'
          : caps.contains('WPA2') ? 'WPA2'
          : caps.contains('WPA')  ? 'WPA'
          : caps.contains('WEP')  ? 'WEP'
          : 'Open';
      return WifiNetwork(
        ssid: ap.ssid,
        bssid: ap.bssid,
        signalStrength: ap.level,
        encryption: encryption,
        frequency: ap.frequency,
        hasWps: caps.contains('WPS'),
      );
    }).toList();
  }
}

enum WifiConnectionResult { success, failed, error }
