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
        title: const Text('New Network Detected'),
        content: Text('You joined "$ssid". Scan for devices?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startScan();
            },
            child: const Text('Scan Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _startScan() async {
    _scanSub?.cancel();
    setState(() {
      _scanning = true;
      _error = null;
      _devices = [];
      _scanProgress = 0;
      _scanTotal = 254;
    });

    try {
      final connectedInfo = await WifiService.getConnectedNetworkInfo();
      final gateway = connectedInfo['gateway'];
      _connectedSsid = connectedInfo['ssid']?.replaceAll('"', '');

      if (gateway == null) {
        setState(() => _error = 'Not connected to a network.');
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

      final nearbyNetworks = await WifiService.scanNearbyNetworks();
      if (nearbyNetworks.isNotEmpty) {
        final connected = nearbyNetworks.firstWhere(
          (n) => n.ssid == _connectedSsid,
          orElse: () => nearbyNetworks.first,
        );
        _connectedEncryption = connected.encryption;
      } else {
        _connectedEncryption = 'WPA2';
      }

      final collectedDevices = <NetworkDevice>[];

      // Stream: devices appear in the list as they are found
      _scanSub = DeviceScanner.scanStream(
        gateway,
        onProgress: (scanned, total) {
          if (mounted) {
            setState(() {
              _scanProgress = scanned;
              _scanTotal = total;
            });
          }
        },
      ).listen(
        (device) {
          if (!mounted) return;
          final tagged = previousIpSet.isNotEmpty &&
                  !previousIpSet.contains(device.ipAddress)
              ? device.copyWith(isNew: true)
              : device;
          collectedDevices.add(tagged);
          setState(() {
            // Keep cameras at top, rest by IP order
            _devices = List.from(collectedDevices)
              ..sort((a, b) {
                if (a.isCamera && !b.isCamera) return -1;
                if (!a.isCamera && b.isCamera) return 1;
                return _ipToInt(a.ipAddress).compareTo(_ipToInt(b.ipAddress));
              });
          });
        },
        onDone: () async {
          if (mounted) { setState(() => _scanning = false); }
          await ApiService.saveDevices(
              sessionId, collectedDevices, _connectedSsid);
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _error = e.toString();
              _scanning = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _scanning = false;
        });
      }
    }
  }

  int _ipToInt(String ip) {
    final parts = ip.split('.').map(int.parse).toList();
    return (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3];
  }

  Future<void> _exportReport() async {
    if (_devices.isEmpty) return;
    final riskResult = RiskScoreService.calculate(
      encryption: _connectedEncryption ?? 'WPA2',
      devices: _devices,
    );
    try {
      await ReportService.generateAndShare(
        networkSsid: _connectedSsid ?? 'Unknown',
        encryption: _connectedEncryption ?? 'Unknown',
        connectedIp: '',
        devices: _devices,
        riskResult: riskResult,
        scanTime: DateTime.now(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameras = _devices.where((d) => d.isCamera).toList();
    final newDevices = _devices.where((d) => d.isNew).toList();
    final hasDevices = _devices.isNotEmpty;

    return Scaffold(
      backgroundColor: kNavyDark,
      appBar: AppBar(
        title: const Text('Network Scanner',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3)),
        centerTitle: true,
        actions: [
          if (hasDevices)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Export Report',
              onPressed: _exportReport,
            ),
        ],
      ),
      body: Column(
        children: [
          // Network banner
          if (_connectedSsid != null)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: kNavy,
                border: Border(bottom: BorderSide(color: kNavyLight)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.wifi_rounded, size: 14, color: kAccent),
                  const SizedBox(width: 6),
                  Text(_connectedSsid!,
                      style: const TextStyle(
                          color: kAccent, fontWeight: FontWeight.w600, fontSize: 13)),
                  const Spacer(),
                  if (_scanning)
                    Text('$_scanProgress / $_scanTotal',
                        style: const TextStyle(
                            color: Color(0xFF4A6080), fontSize: 12)),
                ],
              ),
            ),

          // Progress bar
          if (_scanning)
            ClipRect(
              child: LinearProgressIndicator(
                value: _scanTotal > 0 ? _scanProgress / _scanTotal : null,
                minHeight: 3,
                backgroundColor: kNavyLight,
                valueColor: const AlwaysStoppedAnimation<Color>(kAccent),
              ),
            ),

          // Alert banners
          if (cameras.isNotEmpty) _CameraBanner(count: cameras.length),
          if (newDevices.isNotEmpty) _NewDeviceBanner(count: newDevices.length),

          // Stats row when devices found
          if (hasDevices) _DeviceStatsRow(devices: _devices),

          // Error
          if (_error != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kErrorRed.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kErrorRed.withAlpha(80)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: kErrorRed, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!,
                    style: const TextStyle(color: kErrorRed, fontSize: 13))),
              ]),
            ),

          // Device list or empty state
          Expanded(
            child: !hasDevices
                ? _scanning
                    ? _ScanningEmptyState(progress: _scanProgress, total: _scanTotal)
                    : const _IdleEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _devices.length,
                    itemBuilder: (context, i) => InkWell(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => DeviceDetailScreen(device: _devices[i]))),
                      child: DeviceTile(device: _devices[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanning ? null : _startScan,
        backgroundColor: _scanning ? kNavyLight : kAccent,
        icon: _scanning
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.radar_rounded),
        label: Text(_scanning ? 'Scanning...' : 'Scan Network',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _DeviceStatsRow extends StatelessWidget {
  final List<NetworkDevice> devices;
  const _DeviceStatsRow({required this.devices});

  @override
  Widget build(BuildContext context) {
    final cameras = devices.where((d) => d.isCamera).length;
    final routers = devices.where((d) => d.deviceType.name == 'router').length;
    final iot = devices.where((d) => d.deviceType.name == 'iotDevice').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _StatPill(label: '${devices.length}', sub: 'Total', color: kAccent),
          const SizedBox(width: 8),
          if (cameras > 0) ...[
            _StatPill(label: '$cameras', sub: 'Camera${cameras > 1 ? "s" : ""}', color: kErrorRed),
            const SizedBox(width: 8),
          ],
          if (routers > 0) ...[
            _StatPill(label: '$routers', sub: 'Router${routers > 1 ? "s" : ""}', color: const Color(0xFF5A7AAF)),
            const SizedBox(width: 8),
          ],
          if (iot > 0)
            _StatPill(label: '$iot', sub: 'IoT', color: const Color(0xFFFF8F00)),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  const _StatPill({required this.label, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 4),
          Text(sub, style: TextStyle(color: color.withAlpha(180), fontSize: 11)),
        ],
      ),
    );
  }
}

class _ScanningEmptyState extends StatelessWidget {
  final int progress;
  final int total;
  const _ScanningEmptyState({required this.progress, required this.total});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(strokeWidth: 3, color: kAccent),
          ),
          const SizedBox(height: 20),
          const Text('Scanning network...',
              style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('$progress of $total hosts checked',
              style: const TextStyle(color: Color(0xFF4A6080), fontSize: 13)),
          const SizedBox(height: 4),
          const Text('Devices appear as they are found',
              style: TextStyle(color: Color(0xFF4A6080), fontSize: 12)),
        ],
      ),
    );
  }
}

class _IdleEmptyState extends StatelessWidget {
  const _IdleEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: kNavy,
              shape: BoxShape.circle,
              border: Border.all(color: kNavyLight, width: 2),
            ),
            child: const Icon(Icons.radar_rounded, size: 40, color: Color(0xFF4A6080)),
          ),
          const SizedBox(height: 20),
          const Text('Ready to Scan',
              style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Tap the button below to discover\nall devices on your network',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF4A6080), fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

class _CameraBanner extends StatelessWidget {
  final int count;
  const _CameraBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: cs.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.videocam, color: cs.error),
          const SizedBox(width: 8),
          Text(
            '$count camera${count > 1 ? "s" : ""} detected on this network!',
            style: TextStyle(color: cs.error, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _NewDeviceBanner extends StatelessWidget {
  final int count;
  const _NewDeviceBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.green.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.new_releases, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            '$count new device${count > 1 ? "s" : ""} since last scan',
            style: const TextStyle(
                color: Colors.green, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
