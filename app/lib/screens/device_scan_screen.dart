import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/network_device.dart';
import '../services/wifi_service.dart';
import '../services/device_scanner.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/risk_score_service.dart';
import '../services/report_service.dart';
import '../widgets/device_tile.dart';
import 'device_detail_screen.dart';

class DeviceScanScreen extends StatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  State<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends State<DeviceScanScreen> {
  List<NetworkDevice> _devices = [];
  bool _scanning = false;
  String? _error;
  String? _connectedSsid;
  String? _connectedEncryption;
  int _scanProgress = 0;
  int _scanTotal = 254;
  StreamSubscription? _connectivitySub;
  StreamSubscription<NetworkDevice>? _scanSub;

  @override
  void initState() {
    super.initState();
    ConnectivityService.init();
    _connectivitySub = ConnectivityService.onNewWifiNetwork.listen((ssid) {
      if (!mounted) return;
      _showNewNetworkDialog(ssid ?? 'Unknown');
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  void _showNewNetworkDialog(String ssid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('NEW NETWORK'),
        content: Text('Joined "$ssid"\nRun device scan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('SKIP')),
          FilledButton(onPressed: () { Navigator.pop(ctx); _startScan(); },
              child: const Text('SCAN')),
        ],
      ),
    );
  }

  Future<void> _startScan() async {
    _scanSub?.cancel();
    setState(() {
      _scanning = true; _error = null;
      _devices = []; _scanProgress = 0; _scanTotal = 254;
    });

    try {
      final connectedInfo = await WifiService.getConnectedNetworkInfo();
      final gateway = connectedInfo['gateway'];
      _connectedSsid = connectedInfo['ssid'];
      if (gateway == null) {
        setState(() => _error = 'NOT CONNECTED TO ANY NETWORK');
        return;
      }

      final previousIps = _connectedSsid != null
          ? await ApiService.getLastSessionIps(_connectedSsid!)
          : <String>[];
      final previousIpSet = previousIps.toSet();

      final sessionId = await ApiService.createSession(
        connectedSsid: _connectedSsid,
        connectedBssid: connectedInfo['bssid'],
        connectedIp: connectedInfo['ip'],
      );

      final nearby = await WifiService.scanNearbyNetworks();
      if (nearby.isNotEmpty) {
        final conn = nearby.firstWhere(
            (n) => n.ssid == _connectedSsid, orElse: () => nearby.first);
        _connectedEncryption = conn.encryption;
      } else {
        _connectedEncryption = 'WPA2';
      }

      final collected = <NetworkDevice>[];

      _scanSub = DeviceScanner.scanStream(gateway,
        onProgress: (scanned, total) {
          if (mounted) {
            setState(() { _scanProgress = scanned; _scanTotal = total; });
          }
        },
      ).listen(
        (device) {
          if (!mounted) return;
          final tagged = previousIpSet.isNotEmpty && !previousIpSet.contains(device.ipAddress)
              ? device.copyWith(isNew: true) : device;
          collected.add(tagged);
          setState(() {
            _devices = List.from(collected)
              ..sort((a, b) {
                if (a.isCamera && !b.isCamera) return -1;
                if (!a.isCamera && b.isCamera) return 1;
                return _ipToInt(a.ipAddress).compareTo(_ipToInt(b.ipAddress));
              });
          });
        },
        onDone: () async {
          if (mounted) { setState(() => _scanning = false); }
          await ApiService.saveDevices(sessionId, collected, _connectedSsid);
        },
        onError: (e) {
          if (mounted) {
            setState(() { _error = e.toString(); _scanning = false; });
          }
        },
      );
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _scanning = false; });
    }
  }

  int _ipToInt(String ip) {
    final p = ip.split('.').map(int.parse).toList();
    return (p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3];
  }

  Future<void> _exportReport() async {
    if (_devices.isEmpty) return;
    final risk = RiskScoreService.calculate(
        encryption: _connectedEncryption ?? 'WPA2', devices: _devices);
    try {
      await ReportService.generateAndShare(
        networkSsid: _connectedSsid ?? 'Unknown',
        encryption: _connectedEncryption ?? 'Unknown',
        connectedIp: '',
        devices: _devices,
        riskResult: risk,
        scanTime: DateTime.now(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('REPORT_ERROR: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameras    = _devices.where((d) => d.isCamera).toList();
    final newDevices = _devices.where((d) => d.isNew).toList();
    final hasDevices = _devices.isNotEmpty;

    return Scaffold(
      backgroundColor: kTerminalBg,
      appBar: AppBar(
        title: const Text('NETWORK_SCAN'),
        actions: [
          if (hasDevices)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              onPressed: _exportReport,
              tooltip: 'Export Report',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kGreenDim.withAlpha(80)),
        ),
      ),
      body: Column(
        children: [
          // Network status bar
          if (_connectedSsid != null)
            Container(
              color: kGreenFaint,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(children: [
                const Icon(Icons.wifi_rounded, size: 12, color: kGreen),
                const SizedBox(width: 6),
                Text(_connectedSsid!,
                    style: const TextStyle(color: kGreen, fontFamily: 'monospace',
                        fontSize: 11, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_scanning)
                  Text('$_scanProgress/$_scanTotal',
                      style: const TextStyle(color: kGrayText,
                          fontFamily: 'monospace', fontSize: 10)),
              ]),
            ),

          // Progress bar
          if (_scanning)
            LinearProgressIndicator(
              value: _scanTotal > 0 ? _scanProgress / _scanTotal : null,
              minHeight: 2,
              backgroundColor: kTerminalBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(kGreen),
            ),

          // Alert banners
          if (cameras.isNotEmpty)
            _AlertBanner(
              '${cameras.length} CAMERA${cameras.length > 1 ? "S" : ""} DETECTED ON NETWORK',
              color: kOrange, icon: Icons.videocam_rounded),
          if (newDevices.isNotEmpty)
            _AlertBanner('${newDevices.length} NEW DEVICE${newDevices.length > 1 ? "S" : ""} SINCE LAST SCAN',
                color: kCyan, icon: Icons.new_releases_rounded),

          // Stats pills
          if (hasDevices) _StatsRow(devices: _devices),

          // Error
          if (_error != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  border: Border.all(color: kRed), color: kRed.withAlpha(15)),
              child: Text('ERROR: $_error',
                  style: const TextStyle(color: kRed,
                      fontFamily: 'monospace', fontSize: 11)),
            ),

          Expanded(
            child: !hasDevices
                ? _scanning
                    ? _ScanningState(progress: _scanProgress, total: _scanTotal)
                    : const _IdleState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _devices.length,
                    itemBuilder: (ctx, i) => GestureDetector(
                      onTap: () => Navigator.push(ctx, MaterialPageRoute(
                          builder: (_) => DeviceDetailScreen(device: _devices[i]))),
                      child: DeviceTile(device: _devices[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanning ? null : _startScan,
        backgroundColor: _scanning ? kTerminalBorder : kGreen,
        foregroundColor: kTerminalBg,
        icon: _scanning
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: kTerminalBg))
            : const Icon(Icons.radar_rounded, size: 18),
        label: Text(_scanning ? 'SCANNING...' : 'SCAN NETWORK',
            style: const TextStyle(fontFamily: 'monospace',
                fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
        shape: const RoundedRectangleBorder(),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;
  const _AlertBanner(this.message, {required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      color: color.withAlpha(20),
      child: Row(children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 8),
        Text(message, style: TextStyle(color: color,
            fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<NetworkDevice> devices;
  const _StatsRow({required this.devices});

  @override
  Widget build(BuildContext context) {
    final cameras  = devices.where((d) => d.isCamera).length;
    final routers  = devices.where((d) => d.deviceType.name == 'router').length;
    final iot      = devices.where((d) => d.deviceType.name == 'iotDevice').length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(spacing: 8, runSpacing: 6, children: [
        _Pill('${devices.length} HOSTS', kGreen),
        if (cameras > 0) _Pill('$cameras CAM${cameras > 1 ? "S" : ""}', kOrange),
        if (routers > 0) _Pill('$routers ROUTER${routers > 1 ? "S" : ""}', kCyan),
        if (iot > 0)     _Pill('$iot IOT', kGrayText),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(80)),
        color: color.withAlpha(15),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10,
              fontFamily: 'monospace', letterSpacing: 0.5)),
    );
  }
}

class _ScanningState extends StatelessWidget {
  final int progress;
  final int total;
  const _ScanningState({required this.progress, required this.total});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
          width: 60, height: 60,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: kGreen),
        ),
        const SizedBox(height: 20),
        const Text('SCANNING NETWORK...',
            style: TextStyle(color: kGreen, fontFamily: 'monospace',
                fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('$progress / $total HOSTS CHECKED',
            style: const TextStyle(color: kGrayText, fontFamily: 'monospace', fontSize: 11)),
        const SizedBox(height: 4),
        const Text('DEVICES APPEAR IN REAL-TIME',
            style: TextStyle(color: kDimText, fontFamily: 'monospace', fontSize: 10)),
      ]),
    );
  }
}

class _IdleState extends StatelessWidget {
  const _IdleState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: kGreenDim, width: 1),
            shape: BoxShape.rectangle,
            color: kGreenFaint,
          ),
          child: const Icon(Icons.radar_rounded, size: 40, color: kGreenDim),
        ),
        const SizedBox(height: 20),
        const Text('READY',
            style: TextStyle(color: kGreen, fontFamily: 'monospace',
                fontSize: 18, letterSpacing: 4, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('PRESS SCAN TO SWEEP THE NETWORK',
            style: TextStyle(color: kGrayText, fontFamily: 'monospace', fontSize: 11, letterSpacing: 1)),
      ]),
    );
  }
}
