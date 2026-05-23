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
  bool _showOpenOnly = false;
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
      // ── Phase 1: instant (<100 ms) ────────────────────────────────────────
      // Connected info and cached scan results need no startScan().
      // This renders the connected card and a first list almost immediately.
      final connectedInfoFuture = WifiService.getConnectedNetworkInfo();
      final cachedFuture        = WifiService.getCachedNetworks();
      final connectedInfo       = await connectedInfoFuture;
      final cached              = await cachedFuture;
      final connectedBssid      = connectedInfo['bssid'];

      if (!mounted) return;
      setState(() {
        _connectedInfo = connectedInfo;
        if (cached.isNotEmpty) {
          _networks = _tagAndSort(cached, connectedBssid);
        }
      });

      // ── Phase 2: fresh scan (2–5 s) ───────────────────────────────────────
      // Runs startScan() — list refreshes when done, spinner stays visible.
      final fresh = await WifiService.scanNearbyNetworks();
      if (!mounted) return;
      final tagged = _tagAndSort(fresh, connectedBssid);
      setState(() => _networks = tagged);

      // ── Phase 3: background API calls ─────────────────────────────────────
      // Don't await — risk score and camera count update silently.
      _loadApiData(connectedInfo['ssid'] ?? '', tagged);

    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  List<WifiNetwork> _tagAndSort(List<WifiNetwork> networks, String? connectedBssid) {
    return networks.map((n) => WifiNetwork(
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
  }

  Future<void> _loadApiData(String ssid, List<WifiNetwork> tagged) async {
    if (ssid.isEmpty) return;
    try {
      final results = await Future.wait([
        ApiService.getLastSessionIps(ssid),
        ApiService.getCameraHistory(),
      ]);
      final lastIps = results[0] as List<String>;
      final cameras = results[1] as List<Map<String, dynamic>>;

      final cameraCount = cameras.where((c) => c['network_ssid'] == ssid).length;
      final cameraIps   = cameras.map((c) => c['ip_address'] as String?).toSet();
      final lastDevices = lastIps.map((ip) =>
          NetworkDevice(ipAddress: ip, isCamera: cameraIps.contains(ip))).toList();

      final connectedNet = tagged.where((n) => n.isConnected).firstOrNull ??
          (tagged.isNotEmpty ? tagged.first
              : WifiNetwork(ssid: ssid, bssid: '', signalStrength: -70,
                  encryption: 'WPA2', frequency: 2400));

      if (!mounted) return;
      setState(() {
        _riskResult = RiskScoreService.calculate(
            encryption: connectedNet.encryption, devices: lastDevices);
        _cameraCount = cameraCount;
      });
      ApiService.saveNetworkScan(tagged).catchError((_) {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final connectedNetwork = _networks.where((n) => n.isConnected).firstOrNull;
    final encryption = connectedNetwork?.encryption ?? '';

    final openNetworks = _networks.where((n) => n.isOpen).toList();
    final fiveGHz  = _networks.where((n) => n.frequency >= 5000).length;
    final secured  = _networks.where((n) => !n.isOpen).length;
    final wpsCount = _networks.where((n) => n.hasWps).length;

    final displayedNetworks = _showOpenOnly ? openNetworks : _networks;

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
              child: ConnectedNetworkCard(
                info: _connectedInfo,
                encryption: encryption,
                connectedNetwork: connectedNetwork,
              ),
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
                      if (openNetworks.isNotEmpty)
                        _StatBox('${openNetworks.length}', 'OPEN!',
                            color: kRed, highlighted: true),
                      if (wpsCount > 0)
                        _StatBox('$wpsCount', 'WPS!', color: kOrange),
                    ],
                  ),
                ),
              ),

            if (_riskResult != null)
              SliverToBoxAdapter(child: RiskScoreCard(result: _riskResult!)),

            // Open network threat alert
            if (openNetworks.isNotEmpty)
              SliverToBoxAdapter(
                child: _OpenNetworkAlert(
                  count: openNetworks.length,
                  networks: openNetworks,
                  showOpenOnly: _showOpenOnly,
                  onToggle: () => setState(() => _showOpenOnly = !_showOpenOnly),
                ),
              ),

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
                  Icon(
                    _showOpenOnly ? Icons.warning_amber_rounded : Icons.wifi_find_rounded,
                    size: 12,
                    color: _showOpenOnly ? kRed : kGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showOpenOnly
                        ? 'OPEN_NETWORKS [${openNetworks.length}]'
                        : 'WIFI_NETWORKS [${_networks.length}]',
                    style: TextStyle(
                      color: _showOpenOnly ? kRed : kGreen,
                      fontSize: 10,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                    ),
                  ),
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
                      style: const TextStyle(
                          color: kRed, fontFamily: 'monospace', fontSize: 11)),
                ),
              )
            else if (displayedNetworks.isEmpty && !_scanning)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        _showOpenOnly
                            ? Icons.verified_user_rounded
                            : Icons.wifi_off_rounded,
                        color: _showOpenOnly ? kGreen : kDimText,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _showOpenOnly
                            ? 'NO OPEN NETWORKS FOUND'
                            : 'NO NETWORKS FOUND',
                        style: const TextStyle(
                            color: kGrayText, fontFamily: 'monospace',
                            fontSize: 12, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _showOpenOnly
                            ? 'ALL NEARBY NETWORKS ARE SECURED'
                            : 'PULL DOWN TO SCAN',
                        style: const TextStyle(
                            color: kDimText, fontFamily: 'monospace', fontSize: 10),
                      ),
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
                        network: displayedNetworks[i], onConnected: _scan),
                    childCount: displayedNetworks.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OpenNetworkAlert extends StatelessWidget {
  final int count;
  final List<WifiNetwork> networks;
  final bool showOpenOnly;
  final VoidCallback onToggle;

  const _OpenNetworkAlert({
    required this.count,
    required this.networks,
    required this.showOpenOnly,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Sort open networks by signal strength (closest first)
    final sorted = [...networks]..sort((a, b) => b.signalStrength.compareTo(a.signalStrength));
    final strongest = sorted.first;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        border: Border.all(color: kRed, width: 1),
        color: kRed.withAlpha(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert header
          Container(
            width: double.infinity,
            color: kRed.withAlpha(30),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: kRed, size: 14),
                const SizedBox(width: 8),
                Text(
                  'THREAT DETECTED: $count OPEN ${count == 1 ? 'NETWORK' : 'NETWORKS'}',
                  style: const TextStyle(
                    color: kRed,
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: kRed.withAlpha(150)),
                    ),
                    child: Text(
                      showOpenOnly ? 'SHOW ALL' : 'FILTER',
                      style: const TextStyle(
                        color: kRed,
                        fontSize: 9,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Strongest open network summary
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'NEAREST OPEN: ',
                      style: TextStyle(
                          color: kGrayText, fontSize: 10, fontFamily: 'monospace'),
                    ),
                    Expanded(
                      child: Text(
                        strongest.ssid.isEmpty ? '[HIDDEN SSID]' : strongest.ssid,
                        style: const TextStyle(
                          color: kRed,
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _InfoChip('${strongest.signalStrength}dBm', kGrayText),
                    const SizedBox(width: 6),
                    _InfoChip(strongest.distanceLabel, kCyan),
                    const SizedBox(width: 6),
                    _InfoChip(
                      strongest.frequency >= 5000 ? '5GHz' : '2.4GHz',
                      kGrayText,
                    ),
                    if (strongest.hasWps) ...[
                      const SizedBox(width: 6),
                      _InfoChip('WPS!', kOrange),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '! Unencrypted traffic — anyone nearby can intercept data',
                  style: TextStyle(
                      color: kRed,
                      fontSize: 9,
                      fontFamily: 'monospace',
                      letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(border: Border.all(color: color.withAlpha(100))),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontFamily: 'monospace'),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool highlighted;
  const _StatBox(this.value, this.label,
      {this.color = kGrayText, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: highlighted ? kRed.withAlpha(20) : kTerminalCard,
          border: Border.all(color: highlighted ? kRed : kTerminalBorder),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(label,
              style: const TextStyle(
                  color: kDimText, fontFamily: 'monospace',
                  fontSize: 8, letterSpacing: 1)),
        ]),
      ),
    );
  }
}
