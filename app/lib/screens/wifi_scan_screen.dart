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
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_scanning) _scan();
    });
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

      final networks = results[0] as List<WifiNetwork>;
      final connectedInfo = results[1] as Map<String, String?>;
      final connectedBssid = connectedInfo['bssid'];
      final connectedSsid = connectedInfo['ssid']?.replaceAll('"', '') ?? '';

      final tagged = networks.map((n) => WifiNetwork(
            ssid: n.ssid,
            bssid: n.bssid,
            signalStrength: n.signalStrength,
            encryption: n.encryption,
            frequency: n.frequency,
            isConnected: n.bssid == connectedBssid,
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
          lastDevices = lastIps.map((ip) => NetworkDevice(
                ipAddress: ip, isCamera: cameraIps.contains(ip))).toList();
        } catch (_) {}
      }

      final connectedNetwork = tagged.firstWhere(
        (n) => n.isConnected,
        orElse: () => tagged.isNotEmpty
            ? tagged.first
            : WifiNetwork(ssid: connectedSsid, bssid: '', signalStrength: -70, encryption: 'WPA2', frequency: 2400),
      );

      if (!mounted) return;
      setState(() {
        _networks = tagged;
        _connectedInfo = connectedInfo;
        _riskResult = RiskScoreService.calculate(encryption: connectedNetwork.encryption, devices: lastDevices);
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
    final fiveGHz = _networks.where((n) => n.frequency >= 5000).length;
    final secured = _networks.where((n) => n.encryption != 'Open').length;
    final encryption = _networks.isEmpty ? '' :
        (_networks.firstWhere((n) => n.isConnected, orElse: () => _networks.first).encryption);

    return Scaffold(
      backgroundColor: kNavyDark,
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 34),
        centerTitle: true,
        actions: [
          if (_scanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kAccent)),
            )
          else
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _scan, tooltip: 'Refresh'),
        ],
      ),
      body: RefreshIndicator(
        color: kAccent,
        backgroundColor: kNavy,
        onRefresh: _scan,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: ConnectedNetworkCard(info: _connectedInfo, encryption: encryption)),

            // Stats row
            if (_networks.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Row(
                    children: [
                      _StatChip(value: '${_networks.length}', label: 'Networks', icon: Icons.wifi_rounded),
                      const SizedBox(width: 8),
                      _StatChip(value: '$secured', label: 'Secured', icon: Icons.lock_rounded, color: kAccent),
                      const SizedBox(width: 8),
                      _StatChip(value: '$fiveGHz', label: '5 GHz', icon: Icons.speed_rounded),
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_find_rounded, size: 16, color: kAccent),
                    const SizedBox(width: 6),
                    Text('Nearby Networks',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: kOffWhite, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                    const Spacer(),
                    if (_networks.isNotEmpty)
                      Text('Tap to connect',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF4A6080))),
                  ],
                ),
              ),
            ),

            if (_error != null)
              SliverToBoxAdapter(
                child: _ErrorBanner(message: _error!),
              )
            else if (_networks.isEmpty && !_scanning)
              SliverToBoxAdapter(child: _EmptyNetworks())
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => WifiNetworkTile(network: _networks[i], onConnected: _scan),
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

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.value,
    required this.label,
    required this.icon,
    this.color = const Color(0xFF5A7AAF),
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: kNavy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kNavyLight),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ],
            ),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF4A6080), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kErrorRed.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kErrorRed.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: kErrorRed, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: const TextStyle(color: kErrorRed, fontSize: 13))),
        ],
      ),
    );
  }
}

class _EmptyNetworks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: kNavyLight),
          const SizedBox(height: 12),
          const Text('No networks found',
              style: TextStyle(color: kOffWhite, fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          const Text('Pull down to scan',
              style: TextStyle(color: Color(0xFF4A6080), fontSize: 13)),
        ],
      ),
    );
  }
}
