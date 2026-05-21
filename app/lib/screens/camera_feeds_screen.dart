import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/wifi_service.dart';
import '../widgets/camera_feed_tile.dart';

class CameraFeedsScreen extends StatefulWidget {
  const CameraFeedsScreen({super.key});

  @override
  State<CameraFeedsScreen> createState() => _CameraFeedsScreenState();
}

class _CameraFeedsScreenState extends State<CameraFeedsScreen> {
  List<Map<String, dynamic>> _cameras = [];
  bool _loading = true;
  String? _networkSsid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final info = await WifiService.getConnectedNetworkInfo();
      _networkSsid = info['ssid']?.replaceAll('"', '');

      List<Map<String, dynamic>> cameras;
      if (_networkSsid != null && _networkSsid!.isNotEmpty) {
        cameras = await ApiService.getCamerasForNetwork(_networkSsid!);
        if (cameras.isEmpty) {
          cameras = await ApiService.getAllCameras();
        }
      } else {
        cameras = await ApiService.getAllCameras();
      }

      // Deduplicate by IP
      final seen = <String>{};
      cameras = cameras.where((c) => seen.add(c['ip_address'] ?? '')).toList();

      if (!mounted) return;
      setState(() => _cameras = cameras);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavyDark,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Camera Feeds',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (_networkSsid != null)
              Text(_networkSsid!,
                  style: const TextStyle(
                      color: kAccent, fontSize: 11, fontWeight: FontWeight.normal)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : _cameras.isEmpty
              ? _EmptyState(onRefresh: _load)
              : RefreshIndicator(
                  color: kAccent,
                  backgroundColor: kNavy,
                  onRefresh: _load,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        childAspectRatio: 16 / 10,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _cameras.length,
                      itemBuilder: (ctx, i) => CameraFeedTile(
                        camera: _cameras[i],
                        onFullscreen: () => _openFullscreen(context, _cameras[i]),
                      ),
                    ),
                  ),
                ),
    );
  }

  void _openFullscreen(BuildContext context, Map<String, dynamic> camera) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenFeedScreen(camera: camera),
      ),
    ).then((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    });
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

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
            child: const Icon(Icons.videocam_off_rounded,
                size: 38, color: Color(0xFF4A6080)),
          ),
          const SizedBox(height: 20),
          const Text('No Cameras Found',
              style: TextStyle(
                  color: kWhite, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Scan your network first to detect CCTV cameras',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF4A6080), fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class FullscreenFeedScreen extends StatelessWidget {
  final Map<String, dynamic> camera;
  const FullscreenFeedScreen({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: kWhite,
        title: Text(camera['ip_address'] ?? '',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen_exit_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: CameraFeedTile(
        camera: camera,
        fullscreen: true,
        onFullscreen: () => Navigator.pop(context),
      ),
    );
  }
}
