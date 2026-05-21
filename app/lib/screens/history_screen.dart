import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _cameras = [];
  List<Map<String, dynamic>> _networks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getCameraHistory(),
        ApiService.getScanHistory(),
      ]);
      setState(() {
        _cameras = results[0];
        _networks = results[1];
      });
    } catch (e) {
      setState(() => _error = 'Could not load history. Is the backend running?');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.videocam), text: 'Cameras'),
            Tab(icon: Icon(Icons.wifi), text: 'Networks'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _CameraHistoryList(cameras: _cameras),
                    _NetworkHistoryList(networks: _networks),
                  ],
                ),
    );
  }
}

class _CameraHistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> cameras;
  const _CameraHistoryList({required this.cameras});

  @override
  Widget build(BuildContext context) {
    if (cameras.isEmpty) {
      return const Center(child: Text('No cameras detected yet.'));
    }
    return ListView.builder(
      itemCount: cameras.length,
      itemBuilder: (context, i) {
        final c = cameras[i];
        return ListTile(
          leading: Icon(Icons.videocam,
              color: Theme.of(context).colorScheme.error),
          title: Text(c['ip_address'] ?? ''),
          subtitle: Text(
            '${c['manufacturer'] ?? 'Unknown'} · ${c['network_ssid'] ?? ''}\n${c['detected_at'] ?? ''}',
          ),
          isThreeLine: true,
        );
      },
    );
  }
}

class _NetworkHistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> networks;
  const _NetworkHistoryList({required this.networks});

  @override
  Widget build(BuildContext context) {
    if (networks.isEmpty) {
      return const Center(child: Text('No network scan history yet.'));
    }
    return ListView.builder(
      itemCount: networks.length,
      itemBuilder: (context, i) {
        final n = networks[i];
        return ListTile(
          leading: const Icon(Icons.wifi),
          title: Text(n['ssid'] ?? ''),
          subtitle: Text(
            '${n['encryption'] ?? ''} · ${n['signal_strength']} dBm\n${n['scanned_at'] ?? ''}',
          ),
          isThreeLine: true,
        );
      },
    );
  }
}
