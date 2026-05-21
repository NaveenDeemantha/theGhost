import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:dart_ping/dart_ping.dart';
import 'package:video_player/video_player.dart';
import '../models/network_device.dart';
import '../models/device_type.dart';
import '../main.dart';

class DeviceDetailScreen extends StatefulWidget {
  final NetworkDevice device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  VideoPlayerController? _videoController;
  bool _loadingStream = false;
  bool _streamError = false;
  bool _streamPlaying = false;

  // HTTP banner grab
  String? _httpBanner;
  bool _grabbing = false;

  // Ping
  List<int> _pingResults = [];   // ms per reply
  int _pingLoss = 0;
  bool _pinging = false;

  NetworkDevice get d => widget.device;

  @override
  void initState() {
    super.initState();
    if (d.httpPort != null) _grabHttpBanner();
    _runPing();
  }

  Future<void> _runPing() async {
    setState(() { _pinging = true; _pingResults = []; _pingLoss = 0; });
    try {
      final ping = Ping(d.ipAddress, count: 4, timeout: 2);
      await for (final event in ping.stream) {
        if (!mounted) break;
        if (event.response != null) {
          final ms = event.response!.time?.inMilliseconds;
          if (ms != null) setState(() => _pingResults.add(ms));
        } else if (event.error != null) {
          setState(() => _pingLoss++);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _pinging = false);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _grabHttpBanner() async {
    setState(() => _grabbing = true);
    try {
      final scheme = (d.httpPort == 443 || d.httpPort == 8443) ? 'https' : 'http';
      final uri = Uri.parse('$scheme://${d.ipAddress}:${d.httpPort}/');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      final server = response.headers['server'];
      final xPowered = response.headers['x-powered-by'];
      final contentType = response.headers['content-type'];
      if (!mounted) return;
      setState(() {
        _httpBanner = [
          if (server != null) 'Server: $server',
          if (xPowered != null) 'X-Powered-By: $xPowered',
          if (contentType != null) 'Content-Type: $contentType',
          'HTTP ${response.statusCode}',
        ].join('\n');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _httpBanner = 'Could not reach HTTP service');
    } finally {
      if (mounted) setState(() => _grabbing = false);
    }
  }

  Future<void> _tryRtspPreview() async {
    if (d.rtspPort == null) return;
    setState(() {
      _loadingStream = true;
      _streamError = false;
    });

    final url = 'rtsp://${d.ipAddress}:${d.rtspPort}/';
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize().timeout(const Duration(seconds: 8));
      setState(() {
        _videoController = controller;
        _streamPlaying = true;
        _loadingStream = false;
      });
      controller.play();
    } catch (_) {
      setState(() {
        _streamError = true;
        _loadingStream = false;
      });
    }
  }

  void _copyIp() {
    Clipboard.setData(ClipboardData(text: d.ipAddress));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('IP copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeExt = d.deviceType;

    return Scaffold(
      appBar: AppBar(
        title: Text(d.ipAddress),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.copy), onPressed: _copyIp),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Device type header
          Card(
            color: d.isCamera ? colorScheme.errorContainer : colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(typeExt.icon,
                      size: 40,
                      color: d.isCamera ? colorScheme.error : colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(typeExt.label,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(d.ipAddress,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontFamily: 'monospace')),
                        if (d.isCamera && d.cameraConfidence != null)
                          Chip(
                            label: Text(
                                '${d.cameraConfidence!.toUpperCase()} confidence'),
                            backgroundColor: colorScheme.error.withAlpha(30),
                            labelStyle: TextStyle(color: colorScheme.error, fontSize: 11),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ),
                  if (d.isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('NEW',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Device info
          _Section(title: 'Device Info', children: [
            _InfoRow('IP Address', d.ipAddress),
            if (d.hostname != null) _InfoRow('Hostname', d.hostname!),
            if (d.macAddress != null) _InfoRow('MAC Address', d.macAddress!),
            if (d.manufacturer != null) _InfoRow('Manufacturer', d.manufacturer!),
            _InfoRow('Device Type', d.deviceType.label),
          ]),
          const SizedBox(height: 12),

          // Ping results
          _Section(
            title: 'Ping Results',
            children: [
              if (_pinging && _pingResults.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: kAccent)),
                    SizedBox(width: 10),
                    Text('Pinging...', style: TextStyle(color: Color(0xFF8AAAD4), fontSize: 12)),
                  ]),
                )
              else if (_pingResults.isEmpty && !_pinging)
                Row(children: [
                  const Text('No response', style: TextStyle(color: kErrorRed, fontSize: 12)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _runPing,
                    icon: const Icon(Icons.refresh_rounded, size: 13),
                    label: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
                ])
              else ...[
                Row(
                  children: [
                    _PingChip(
                      label: 'Min',
                      value: '${_pingResults.reduce((a, b) => a < b ? a : b)} ms',
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _PingChip(
                      label: 'Avg',
                      value: '${(_pingResults.reduce((a, b) => a + b) / _pingResults.length).round()} ms',
                      color: kAccent,
                    ),
                    const SizedBox(width: 8),
                    _PingChip(
                      label: 'Max',
                      value: '${_pingResults.reduce((a, b) => a > b ? a : b)} ms',
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _PingChip(
                      label: 'Loss',
                      value: '$_pingLoss / ${_pingResults.length + _pingLoss}',
                      color: _pingLoss > 0 ? kErrorRed : Colors.green,
                    ),
                  ],
                ),
                if (_pinging)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Row(children: [
                      SizedBox(width: 12, height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: kAccent)),
                      SizedBox(width: 8),
                      Text('Pinging...', style: TextStyle(color: Color(0xFF5A7AAF), fontSize: 11)),
                    ]),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Open ports
          _Section(
            title: 'Open Ports (${d.openPorts.length})',
            children: d.openPorts.isEmpty
                ? [const _InfoRow('', 'No open ports detected')]
                : d.openPorts
                    .map((p) => _InfoRow(p.toString(), _portLabel(p)))
                    .toList(),
          ),
          const SizedBox(height: 12),

          // HTTP Banner Grab
          if (d.httpPort != null)
            _Section(title: 'HTTP Service Info', children: [
              if (_grabbing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: kAccent)),
                    SizedBox(width: 10),
                    Text('Probing HTTP service...', style: TextStyle(color: Color(0xFF8AAAD4), fontSize: 12)),
                  ]),
                )
              else if (_httpBanner != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kNavyDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kNavyLight),
                  ),
                  child: Text(
                    _httpBanner!,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12, color: kOffWhite, height: 1.6),
                  ),
                )
              else
                Row(children: [
                  Text('Port :${d.httpPort}', style: const TextStyle(color: Color(0xFF8AAAD4), fontSize: 12)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _grabHttpBanner,
                    icon: const Icon(Icons.radar_rounded, size: 14),
                    label: const Text('Probe', style: TextStyle(fontSize: 12)),
                  ),
                ]),
            ]),
          const SizedBox(height: 12),

          // RTSP Preview (cameras only)
          if (d.isCamera && d.rtspPort != null) ...[
            _Section(title: 'Camera Stream Preview', children: [
              if (_streamPlaying && _videoController != null)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                )
              else if (_loadingStream)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_streamError)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Could not connect to stream.\nCamera may require authentication or use a non-standard URL.',
                    style: TextStyle(color: colorScheme.error),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Attempt to preview the RTSP stream at rtsp://${d.ipAddress}:${d.rtspPort}/\n'
                    'Note: works only on unauthenticated cameras.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (!_streamPlaying)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton.icon(
                    onPressed: _loadingStream ? null : _tryRtspPreview,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Try Live Preview'),
                  ),
                ),
              if (_streamPlaying)
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow),
                      onPressed: () {
                        setState(() {
                          _videoController!.value.isPlaying
                              ? _videoController!.pause()
                              : _videoController!.play();
                        });
                      },
                    ),
                    Text('Live: rtsp://${d.ipAddress}:${d.rtspPort}/',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
            ]),
          ],
        ],
      ),
    );
  }

  String _portLabel(int port) {
    const labels = {
      80: 'HTTP Web Interface',
      443: 'HTTPS Web Interface',
      8080: 'HTTP Alternate',
      8443: 'HTTPS Alternate',
      554: 'RTSP (Camera Stream)',
      8554: 'RTSP Alternate',
      37777: 'Dahua Camera',
      34567: 'Dahua Camera (Alt)',
      9100: 'Printer (JetDirect)',
      631: 'Printer (IPP)',
      515: 'Printer (LPD)',
      5000: 'NAS (Synology)',
      5001: 'NAS (Synology HTTPS)',
      445: 'SMB File Sharing',
      8008: 'Smart TV (Chromecast)',
      8009: 'Smart TV (Chromecast TLS)',
      22: 'SSH',
      23: 'Telnet',
    };
    return labels[port] ?? 'Unknown service';
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.primary)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
            ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _PingChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PingChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Color(0xFF5A7AAF), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
