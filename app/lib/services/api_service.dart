import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/wifi_network.dart';
import '../models/network_device.dart';

class ApiService {
  static final _client = http.Client();

  static Future<void> saveNetworkScan(List<WifiNetwork> networks) async {
    await _client.post(
      Uri.parse('${AppConstants.baseUrl}/networks/scan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'networks': networks.map((n) => n.toJson()).toList()}),
    );
  }

  static Future<int> createSession({
    required String? connectedSsid,
    required String? connectedBssid,
    required String? connectedIp,
  }) async {
    final res = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'connectedSsid': connectedSsid,
        'connectedBssid': connectedBssid,
        'connectedIp': connectedIp,
      }),
    );
    final data = jsonDecode(res.body);
    return data['sessionId'];
  }

  static Future<void> saveDevices(
    int sessionId,
    List<NetworkDevice> devices,
    String? networkSsid,
  ) async {
    final devicesJson = devices.map((d) {
      final json = d.toJson();
      json['networkSsid'] = networkSsid;
      return json;
    }).toList();

    await _client.post(
      Uri.parse('${AppConstants.baseUrl}/devices'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sessionId': sessionId, 'devices': devicesJson}),
    );
  }

  static Future<List<Map<String, dynamic>>> getCameraHistory() async {
    final res = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/devices/cameras'),
    );
    final List data = jsonDecode(res.body);
    return data.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getScanHistory() async {
    final res = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/networks/history'),
    );
    final List data = jsonDecode(res.body);
    return data.cast<Map<String, dynamic>>();
  }
}
