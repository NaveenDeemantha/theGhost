import 'package:flutter/material.dart';
import '../models/network_device.dart';
import '../services/wifi_service.dart';
import '../services/device_scanner.dart';
import '../services/api_service.dart';
import '../widgets/device_tile.dart';

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

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _error = null;
      _devices = [];
    });

    try {
      final connectedInfo = await WifiService.getConnectedNetworkInfo();
      final gateway = connectedInfo['gateway'];
      _connectedSsid = connectedInfo['ssid']?.replaceAll('"', '');

      if (gateway == null) {
        setState(() => _error = 'Not connected to a network.');
        return;
      }

      final sessionId = await ApiService.createSession(
        connectedSsid: _connectedSsid,
        connectedBssid: connectedInfo['bssid'],
        connectedIp: connectedInfo['ip'],
      );

      final devices = await DeviceScanner.scanSubnet(gateway);

      setState(() => _devices = devices);

      await ApiService.saveDevices(sessionId, devices, _connectedSsid);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameras = _devices.where((d) => d.isCamera).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Scanner'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_connectedSsid != null)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Scanning on: $_connectedSsid',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (_scanning)
            const LinearProgressIndicator(),
          if (cameras.isNotEmpty)
            _CameraBanner(count: cameras.length),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: _scanning
                        ? const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Scanning network...\nThis may take up to 60 seconds.'),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.devices, size: 64,
                                  color: Theme.of(context).colorScheme.outline),
                              const SizedBox(height: 16),
                              const Text('Tap Scan to discover devices'),
                            ],
                          ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, i) => DeviceTile(device: _devices[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanning ? null : _startScan,
        icon: _scanning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.search),
        label: Text(_scanning ? 'Scanning...' : 'Scan Network'),
      ),
    );
  }
}

class _CameraBanner extends StatelessWidget {
  final int count;
  const _CameraBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.videocam, color: colorScheme.error),
          const SizedBox(width: 8),
          Text(
            '$count camera${count > 1 ? "s" : ""} detected on this network!',
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
