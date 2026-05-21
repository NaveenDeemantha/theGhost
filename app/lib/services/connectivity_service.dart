import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

class ConnectivityService {
  static final _connectivity = Connectivity();
  static final _networkInfo = NetworkInfo();
  static String? _lastSsid;

  static Stream<String?> get onNewWifiNetwork {
    return _connectivity.onConnectivityChanged
        .asyncMap((results) async {
          if (!results.contains(ConnectivityResult.wifi)) return null;
          final ssid = await _networkInfo.getWifiName();
          return ssid?.replaceAll('"', '');
        })
        .where((ssid) {
          if (ssid == null) return false;
          if (ssid == _lastSsid) return false;
          _lastSsid = ssid;
          return true;
        });
  }

  static Future<void> init() async {
    final ssid = await _networkInfo.getWifiName();
    _lastSsid = ssid?.replaceAll('"', '');
  }
}
