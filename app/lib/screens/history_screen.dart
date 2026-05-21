import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';

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
  String _searchQuery = '';
  String? _filterSsid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getCameraHistory(),
        ApiService.getScanHistory(),
      ]);
      if (!mounted) return;
      setState(() { _cameras = results[0]; _networks = results[1]; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load history. Is the backend running?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCameras => _cameras.where((c) {
        final q = _searchQuery;
        final matchSearch = q.isEmpty ||
            (c['ip_address'] ?? '').contains(q) ||
            (c['manufacturer'] ?? '').toLowerCase().contains(q) ||
            (c['network_ssid'] ?? '').toLowerCase().contains(q);
        return matchSearch && (_filterSsid == null || c['network_ssid'] == _filterSsid);
      }).toList();

  List<Map<String, dynamic>> get _filteredNetworks => _networks.where((n) {
        final q = _searchQuery;
        return q.isEmpty ||
            (n['ssid'] ?? '').toLowerCase().contains(q) ||
            (n['encryption'] ?? '').toLowerCase().contains(q);
      }).toList();

  List<String> get _uniqueSsids => _cameras
      .map((c) => c['network_ssid'] as String?)
      .whereType<String>()
      .toSet()
      .toList()
    ..sort();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavyDark,
      appBar: AppBar(
        title: const Text('History',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kAccent,
          indicatorWeight: 2,
          labelColor: kAccent,
          unselectedLabelColor: const Color(0xFF4A6080),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'Cameras  ${_filteredCameras.isEmpty ? "" : "(${_filteredCameras.length})"}'),
            Tab(text: 'Networks  ${_filteredNetworks.isEmpty ? "" : "(${_filteredNetworks.length})"}'),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search IP, SSID, manufacturer...',
                hintStyle: const TextStyle(color: Color(0xFF4A6080), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF4A6080), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Color(0xFF4A6080), size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),

          // SSID filter chips (cameras tab)
          if (_tabController.index == 0 && _uniqueSsids.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _FilterChip(label: 'All', selected: _filterSsid == null,
                      onTap: () => setState(() => _filterSsid = null)),
                  const SizedBox(width: 6),
                  ..._uniqueSsids.map((ssid) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _FilterChip(
                          label: ssid,
                          selected: _filterSsid == ssid,
                          onTap: () => setState(() => _filterSsid = ssid),
                        ),
                      )),
                ],
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kAccent))
                : _error != null
                    ? _ErrorState(message: _error!)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _CameraHistoryList(cameras: _filteredCameras),
                          _NetworkHistoryList(networks: _filteredNetworks),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kAccent.withAlpha(30) : kNavy,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? kAccent : kNavyLight),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? kAccent : const Color(0xFF5A7AAF),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
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
      return const _EmptyState(
          icon: Icons.videocam_off_rounded,
          title: 'No Cameras Detected',
          subtitle: 'Scan a network to detect CCTV cameras');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: cameras.length,
      itemBuilder: (context, i) => _CameraTile(data: cameras[i]),
    );
  }
}

class _CameraTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CameraTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: kNavy,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: kErrorRed, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kErrorRed.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.videocam_rounded, color: kErrorRed, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['ip_address'] ?? '—',
                      style: const TextStyle(
                          color: kWhite,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Row(children: [
                    if (data['manufacturer'] != null) ...[
                      Text(data['manufacturer'],
                          style: const TextStyle(color: kAccent, fontSize: 12)),
                      const Text(' · ', style: TextStyle(color: Color(0xFF4A6080))),
                    ],
                    if (data['network_ssid'] != null)
                      Expanded(
                        child: Text(data['network_ssid'],
                            style: const TextStyle(
                                color: Color(0xFF8AAAD4), fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                  ]),
                  const SizedBox(height: 2),
                  Text(_formatDate(data['detected_at']),
                      style: const TextStyle(color: Color(0xFF4A6080), fontSize: 11)),
                ],
              ),
            ),
            if (data['rtsp_port'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kErrorRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kErrorRed.withAlpha(60)),
                ),
                child: Text(':${data['rtsp_port']}',
                    style: const TextStyle(
                        color: kErrorRed, fontSize: 11, fontFamily: 'monospace')),
              ),
          ],
        ),
      ),
    );
  }
}

class _NetworkHistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> networks;
  const _NetworkHistoryList({required this.networks});

  @override
  Widget build(BuildContext context) {
    if (networks.isEmpty) {
      return const _EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'No Networks Scanned',
          subtitle: 'Scan nearby networks to see history');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: networks.length,
      itemBuilder: (context, i) => _NetworkTile(data: networks[i]),
    );
  }
}

class _NetworkTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _NetworkTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final signal = data['signal_strength'] as int? ?? -100;
    final enc = data['encryption'] as String? ?? '';
    final encColor = enc == 'Open'
        ? Colors.green
        : enc == 'WEP'
            ? Colors.orange
            : kAccent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kNavyLight),
      ),
      child: Row(
        children: [
          Icon(_signalIcon(_signalBars(signal)),
              color: const Color(0xFF5A7AAF), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['ssid'] ?? '(Hidden)',
                    style: const TextStyle(color: kWhite, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 3),
                Row(children: [
                  _MiniChip(label: enc, color: encColor),
                  const SizedBox(width: 6),
                  Text('$signal dBm',
                      style: const TextStyle(color: Color(0xFF8AAAD4), fontSize: 11)),
                  const SizedBox(width: 6),
                  Text(_formatDate(data['scanned_at']),
                      style: const TextStyle(color: Color(0xFF4A6080), fontSize: 11)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _signalBars(int dbm) {
    if (dbm >= -50) return 4;
    if (dbm >= -65) return 3;
    if (dbm >= -75) return 2;
    return 1;
  }

  IconData _signalIcon(int bars) {
    switch (bars) {
      case 4: return Icons.signal_wifi_4_bar;
      case 3: return Icons.network_wifi_3_bar;
      case 2: return Icons.network_wifi_2_bar;
      default: return Icons.network_wifi_1_bar;
    }
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kNavy,
              shape: BoxShape.circle,
              border: Border.all(color: kNavyLight, width: 2),
            ),
            child: Icon(icon, size: 34, color: const Color(0xFF4A6080)),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: kWhite, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: Color(0xFF4A6080), fontSize: 13)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: kErrorRed, size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8AAAD4), fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

String _formatDate(dynamic raw) {
  if (raw == null) return '';
  try {
    final dt = DateTime.parse(raw.toString()).toLocal();
    return '${dt.year}-${_p(dt.month)}-${_p(dt.day)}  ${_p(dt.hour)}:${_p(dt.minute)}';
  } catch (_) {
    return raw.toString();
  }
}

String _p(int n) => n.toString().padLeft(2, '0');
