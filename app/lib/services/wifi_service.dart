import 'package:wifi_scan/wifi_scan.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_iot/wifi_iot.dart' hide WifiNetwork;
import '../models/wifi_network.dart';

class WifiService {
  static final _networkInfo = NetworkInfo();

  static Future<List<WifiNetwork>> scanNearbyNetworks() async {
    final can = await WiFiScan.instance.canStartScan(askPermissions: true);
    if (can != CanStartScan.yes) return [];

    await WiFiScan.instance.startScan();
    final can2 = await WiFiScan.instance.canGetScannedResults(askPermissions: true);
    if (can2 != CanGetScannedResults.yes) return [];

    final results = await WiFiScan.instance.getScannedResults();

    return results.map((ap) {
      final caps = ap.capabilities ?? '';
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
    return {
      'ssid': await _networkInfo.getWifiName(),
      'bssid': await _networkInfo.getWifiBSSID(),
      'ip': await _networkInfo.getWifiIP(),
      'gateway': await _networkInfo.getWifiGatewayIP(),
      'subnet': await _networkInfo.getWifiSubmask(),
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
      );

      if (success) return WifiConnectionResult.success;
      return WifiConnectionResult.failed;
    } catch (e) {
      return WifiConnectionResult.error;
    }
  }

  static Future<void> disconnect() async {
    await WiFiForIoTPlugin.disconnect();
  }
}

enum WifiConnectionResult { success, failed, error }
