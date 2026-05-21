import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../main.dart';
import '../services/rtsp_url_helper.dart';

class CameraFeedTile extends StatefulWidget {
  final Map<String, dynamic> camera;
  final VoidCallback? onFullscreen;
  final bool fullscreen;

  const CameraFeedTile({
    super.key,
    required this.camera,
    this.onFullscreen,
    this.fullscreen = false,
  });

  @override
  State<CameraFeedTile> createState() => _CameraFeedTileState();
}

class _CameraFeedTileState extends State<CameraFeedTile> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _connected = false;
  String? _error;
  String? _activeUrl;
  String? _username;
  String? _password;
  int _urlIndex = 0;
  List<String> _urlsToTry = [];

  String get _ip => widget.camera['ip_address'] ?? '';
  int get _port => (widget.camera['rtsp_port'] as int?) ?? 554;
  String? get _manufacturer => widget.camera['manufacturer'];

  @override
  void initState() {
    super.initState();
    _buildUrls();
    _tryConnect();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _buildUrls() {
    _urlsToTry = RtspUrlHelper.urlsToTry(
      _ip,
      _port,
      username: _username,
      password: _password,
      manufacturer: _manufacturer,
    );
    _urlIndex = 0;
  }

  Future<void> _tryConnect() async {
    if (_urlIndex >= _urlsToTry.length) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not connect. Camera may require authentication.';
        });
      }
      return;
    }

    if (mounted) setState(() { _loading = true; _error = null; });

    final url = _urlsToTry[_urlIndex];
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await ctrl.initialize().timeout(const Duration(seconds: 6));
      if (!mounted) { ctrl.dispose(); return; }
      _controller?.dispose();
      setState(() {
        _controller = ctrl;
        _activeUrl = url;
        _connected = true;
        _loading = false;
        _error = null;
      });
      ctrl.play();
      ctrl.setLooping(true);
    } catch (_) {
      _urlIndex++;
      _tryConnect();
    }
  }

  Future<void> _retry({String? username, String? password}) async {
    _controller?.dispose();
    _controller = null;
    _username = username;
    _password = password;
    _connected = false;
    _buildUrls();
    _tryConnect();
  }

  void _showCredentialDialog() {
    final userCtrl = TextEditingController(text: _username);
    final passCtrl = TextEditingController(text: _password);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kNavy,
        title: const Text('Camera Credentials',
            style: TextStyle(color: kWhite, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userCtrl,
              style: const TextStyle(color: kWhite),
              decoration: const InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: Color(0xFF5A7AAF)),
                hintText: 'admin',
                hintStyle: TextStyle(color: Color(0xFF4A6080)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: kWhite),
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Color(0xFF5A7AAF)),
                hintText: 'admin123',
                hintStyle: TextStyle(color: Color(0xFF4A6080)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF5A7AAF)))),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _retry(
                  username: userCtrl.text.trim(),
                  password: passCtrl.text);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(widget.fullscreen ? 0 : 12),
        border: widget.fullscreen
            ? null
            : Border.all(color: _connected ? kAccent.withAlpha(80) : kNavyLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Video or placeholder
          Positioned.fill(
            child: _connected && _controller != null
                ? AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  )
                : Container(
                    color: const Color(0xFF080F1A),
                    child: Center(
                      child: _loading
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                    color: kAccent, strokeWidth: 2),
                                const SizedBox(height: 10),
                                Text(
                                  'Trying URL ${_urlIndex + 1} / ${_urlsToTry.length}...',
                                  style: const TextStyle(
                                      color: Color(0xFF4A6080), fontSize: 11),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.videocam_off_rounded,
                                    color: Color(0xFF4A6080), size: 36),
                                const SizedBox(height: 8),
                                Text(
                                  _error ?? 'Stream unavailable',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Color(0xFF4A6080), fontSize: 11),
                                ),
                              ],
                            ),
                    ),
                  ),
          ),

          // Top overlay — camera info
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _connected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _ip,
                    style: const TextStyle(
                        color: kWhite,
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                  if (_manufacturer != null) ...[
                    const Text(' · ',
                        style: TextStyle(color: Color(0xFF5A7AAF))),
                    Text(_manufacturer!,
                        style: const TextStyle(
                            color: kAccent, fontSize: 11)),
                  ],
                ],
              ),
            ),
          ),

          // Bottom overlay — controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  if (_connected)
                    _OverlayButton(
                      icon: _controller!.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      onTap: () {
                        setState(() {
                          _controller!.value.isPlaying
                              ? _controller!.pause()
                              : _controller!.play();
                        });
                      },
                    ),
                  _OverlayButton(
                    icon: Icons.key_rounded,
                    onTap: _showCredentialDialog,
                  ),
                  if (!_connected && !_loading)
                    _OverlayButton(
                      icon: Icons.refresh_rounded,
                      onTap: () => _retry(
                          username: _username, password: _password),
                    ),
                  const Spacer(),
                  if (_connected && _activeUrl != null)
                    _UrlChip(url: _activeUrl!),
                  const SizedBox(width: 4),
                  if (widget.onFullscreen != null)
                    _OverlayButton(
                      icon: widget.fullscreen
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      onTap: widget.onFullscreen!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _OverlayButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: kWhite, size: 16),
      ),
    );
  }
}

class _UrlChip extends StatelessWidget {
  final String url;
  const _UrlChip({required this.url});

  @override
  Widget build(BuildContext context) {
    final display = RtspUrlHelper.displayUrl(url);
    final path = Uri.tryParse(display)?.path ?? display;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        path.isEmpty ? '/' : path,
        style: const TextStyle(
            color: Color(0xFF8AAAD4), fontSize: 10, fontFamily: 'monospace'),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
