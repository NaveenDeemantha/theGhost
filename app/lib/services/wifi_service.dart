import 'package:wifi_scan/wifi_scan.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_iot/wifi_iot.dart' hide WifiNetwork;
import 'package:permission_handler/permission_handler.dart';
import '../models/wifi_network.dart';

class WifiService {
  static final _networkInfo = NetworkInfo();

  static Future<List<WifiNetwork>> scanNearbyNetworks() async {
    // Ensure location permission is granted before scanning
    final locStatus = await Permission.location.status;
    if (!locStatus.isGranted) await Permission.location.request();

    final can = await WiFiScan.instance.canStartScan(askPermissions: true);
    if (can != CanStartScan.yes) return [];

    await WiFiScan.instance.startScan();
    final can2 = await WiFiScan.instance.canGetScannedResults(askPermissions: true);
    if (can2 != CanGetScannedResults.yes) return [];

    final results = await WiFiScan.instance.getScannedResults();

    return results.map((ap) {
      final caps = ap.capabilities;
      String encryption = 'Open';
      if (caps.contains('WPA3')) {
        encryption = 'WPA3';
      } else if (caps.contains('WPA2')) {
        encryption = 'WPA2';
      } else if (caps.contains('WPA')) {
        encryption = 'WPA';
      } else if (caps.contains('WEP')) {
        encryption = 'WEP';
      }
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

  static Future<Map<String, String?>> getConnectedNetworkInfo() async {
    // Ensure permission before reading network info
    await Permission.location.request();

    String? ssid     = await _networkInfo.getWifiName();
    String? bssid    = await _networkInfo.getWifiBSSID();
    String? ip       = await _networkInfo.getWifiIP();
    String? gateway  = await _networkInfo.getWifiGatewayIP();
    String? subnet   = await _networkInfo.getWifiSubmask();

    // Strip surrounding quotes Android sometimes adds to SSID
    ssid = ssid?.replaceAll('"', '').trim();
    if (ssid == null || ssid.isEmpty || ssid == '<unknown ssid>') ssid = null;

    // If gateway missing, derive it from the IP (assume /24)
    if ((gateway == null || gateway.isEmpty) && ip != null && ip.isNotEmpty) {
      final parts = ip.split('.');
      if (parts.length == 4) {
        gateway = '${parts[0]}.${parts[1]}.${parts[2]}.1';
      }
    }

    return {
      'ssid': ssid,
      'bssid': bssid,
      'ip': ip,
      'gateway': gateway,
      'subnet': subnet,
    };
  }

  static Future<WifiConnectionResult> connectToNetwork({
    required String ssid,
    required String encryption,
    String? password,
  }) async {
    try {
      final isOpen = encryption == 'Open';
      NetworkSecurity security;
      if (isOpen) {
        security = NetworkSecurity.NONE;
      } else if (encryption == 'WEP') {
        security = NetworkSecurity.WEP;
      } else {
        security = NetworkSecurity.WPA;
      }

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

  static Future<void> disconnect() async {
    await WiFiForIoTPlugin.disconnect();
  }
}

enum WifiConnectionResult { success, failed, error }
