import 'dart:async';
import 'package:flutter/material.dart';
import '../models/wifi_network.dart';
import '../models/network_device.dart';
import '../services/wifi_service.dart';
import '../services/api_service.dart';
import '../services/risk_score_service.dart';
import '../widgets/wifi_network_tile.dart';
import '../widgets/connected_network_card.dart';
import '../widgets/risk_score_card.dart';
import '../widgets/security_tip_card.dart';
import '../main.dart';

class WifiScanScreen extends StatefulWidget {
  const WifiScanScreen({super.key});

  @override
  State<WifiScanScreen> createState() => _WifiScanScreenState();
}

class _WifiScanScreenState extends State<WifiScanScreen> {
  List<WifiNetwork> _networks = [];
  Map<String, String?> _connectedInfo = {};
  RiskResult? _riskResult;
  bool _scanning = false;
  String? _error;
  int _cameraCount = 0;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _scan();
    _autoRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) { if (!_scanning) _scan(); });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_scanning) return;
    setState(() { _scanning = true; _error = null; });
    try {
      final results = await Future.wait([
        WifiService.scanNearbyNetworks(),
        WifiService.getConnectedNetworkInfo(),
      ]);
      final networks    = results[0] as List<WifiNetwork>;
      final connectedInfo = results[1] as Map<String, String?>;
      final connectedBssid = connectedInfo['bssid'];
      final connectedSsid  = connectedInfo['ssid'] ?? '';

      final tagged = networks.map((n) => WifiNetwork(
            ssid: n.ssid, bssid: n.bssid,
            signalStrength: n.signalStrength, encryption: n.encryption,
            frequency: n.frequency,
            isConnected: n.bssid == connectedBssid,
            hasWps: n.hasWps,
          )).toList()
        ..sort((a, b) {
          if (a.isConnected) return -1;
          if (b.isConnected) return 1;
          return b.signalStrength.compareTo(a.signalStrength);
        });

      List<NetworkDevice> lastDevices = [];
      int cameraCount = 0;
      if (connectedSsid.isNotEmpty) {
        try {
          final lastIps = await ApiService.getLastSessionIps(connectedSsid);
          final cameras = await ApiService.getCameraHistory();
          cameraCount = cameras.where((c) => c['network_ssid'] == connectedSsid).length;
          final cameraIps = cameras.map((c) => c['ip_address'] as String?).toSet();
          lastDevices = lastIps.map((ip) =>
              NetworkDevice(ipAddress: ip, isCamera: cameraIps.contains(ip))).toList();
        } catch (_) {}
      }

      final connectedNet = tagged.firstWhere((n) => n.isConnected,
          orElse: () => tagged.isNotEmpty
              ? tagged.first
              : WifiNetwork(ssid: connectedSsid, bssid: '', signalStrength: -70,
                  encryption: 'WPA2', frequency: 2400));

      if (!mounted) return;
      setState(() {
        _networks = tagged;
        _connectedInfo = connectedInfo;
        _riskResult = RiskScoreService.calculate(
            encryption: connectedNet.encryption, devices: lastDevices);
        _cameraCount = cameraCount;
      });
      ApiService.saveNetworkScan(networks).catchError((_) {});
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final encryption = _networks.isEmpty ? '' :
        (_networks.firstWhere((n) => n.isConnected,
            orElse: () => _networks.first).encryption);
    final fiveGHz  = _networks.where((n) => n.frequency >= 5000).length;
    final secured  = _networks.where((n) => n.encryption != 'Open').length;
    final wpsCount = _networks.where((n) => n.hasWps).length;

    return Scaffold(
      backgroundColor: kTerminalBg,
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 32, color: kGreen),
        actions: [
          if (_scanning)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: kGreen)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              onPressed: _scan,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kGreenDim.withAlpha(80)),
        ),
      ),
      body: RefreshIndicator(
        color: kGreen,
        backgroundColor: kTerminalCard,
        onRefresh: _scan,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ConnectedNetworkCard(info: _connectedInfo, encryption: encryption),
            ),

            // Stats row
            if (_networks.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      _StatBox('${_networks.length}', 'TOTAL'),
                      _StatBox('$secured', 'SECURED', color: kGreen),
                      _StatBox('$fiveGHz', '5GHz', color: kCyan),
                      if (wpsCount > 0)
                        _StatBox('$wpsCount', 'WPS!', color: kOrange),
                    ],
                  ),
                ),
              ),

            if (_riskResult != null)
              SliverToBoxAdapter(child: RiskScoreCard(result: _riskResult!)),

            SliverToBoxAdapter(
              child: SecurityTipCard(
                encryption: encryption,
                cameraCount: _cameraCount,
                hasWpsNetworks: _networks.any((n) => n.hasWps),
              ),
            ),

            // Section header
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: kTerminalBorder),
                  color: kGreenFaint,
                ),
                child: Row(children: [
                  const Icon(Icons.wifi_find_rounded, size: 12, color: kGreen),
                  const SizedBox(width: 6),
                  Text('WIFI_NETWORKS [${_networks.length}]',
                      style: const TextStyle(color: kGreen, fontSize: 10,
                          fontFamily: 'monospace', letterSpacing: 1.5)),
                  const Spacer(),
                  const Text('TAP TO CONNECT',
                      style: TextStyle(color: kDimText, fontSize: 9,
                          fontFamily: 'monospace', letterSpacing: 1)),
                ]),
              ),
            ),

            if (_error != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: kRed),
                    color: kRed.withAlpha(15),
                  ),
                  child: Text('ERROR: $_error',
                      style: const TextStyle(color: kRed, fontFamily: 'monospace', fontSize: 11)),
                ),
              )
            else if (_networks.isEmpty && !_scanning)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.wifi_off_rounded, color: kDimText, size: 40),
                      const SizedBox(height: 12),
                      const Text('NO NETWORKS FOUND',
                          style: TextStyle(color: kGrayText, fontFamily: 'monospace',
                              fontSize: 12, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      const Text('PULL DOWN TO SCAN',
                          style: TextStyle(color: kDimText, fontFamily: 'monospace', fontSize: 10)),
                    ]),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => WifiNetworkTile(
                        network: _networks[i], onConnected: _scan),
                    childCount: _networks.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBox(this.value, this.label, {this.color = kGrayText});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: kTerminalCard,
          border: Border.all(color: kTerminalBorder),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(color: color,
              fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: kDimText,
              fontFamily: 'monospace', fontSize: 8, letterSpacing: 1)),
        ]),
      ),
    );
  }
}
