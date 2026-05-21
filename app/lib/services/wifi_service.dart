import 'package:wifi_scan/wifi_scan.dart';
import 'package:network_info_plus/network_info_plus.dart';
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
}
