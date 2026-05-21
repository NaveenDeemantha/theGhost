import 'package:flutter/material.dart';
import '../models/wifi_network.dart';
import '../services/wifi_service.dart';
import '../services/api_service.dart';
import '../widgets/wifi_network_tile.dart';
import '../widgets/connected_network_card.dart';

class WifiScanScreen extends StatefulWidget {
  const WifiScanScreen({super.key});

  @override
  State<WifiScanScreen> createState() => _WifiScanScreenState();
}

class _WifiScanScreenState extends State<WifiScanScreen> {
  List<WifiNetwork> _networks = [];
  Map<String, String?> _connectedInfo = {};
  bool _scanning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        WifiService.scanNearbyNetworks(),
        WifiService.getConnectedNetworkInfo(),
      ]);

      final networks = results[0] as List<WifiNetwork>;
      final connectedInfo = results[1] as Map<String, String?>;
      final connectedBssid = connectedInfo['bssid'];

      final tagged = networks.map((n) {
        return WifiNetwork(
          ssid: n.ssid,
          bssid: n.bssid,
          signalStrength: n.signalStrength,
          encryption: n.encryption,
          frequency: n.frequency,
          isConnected: n.bssid == connectedBssid,
        );
      }).toList()
        ..sort((a, b) => b.signalStrength.compareTo(a.signalStrength));

      setState(() {
        _networks = tagged;
        _connectedInfo = connectedInfo;
      });

      ApiService.saveNetworkScan(networks).catchError((_) {});
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TheGhost'),
        centerTitle: true,
        actions: [
          if (_scanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _scan,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _scan,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ConnectedNetworkCard(info: _connectedInfo),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Nearby Networks (${_networks.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => WifiNetworkTile(network: _networks[i]),
                  childCount: _networks.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
