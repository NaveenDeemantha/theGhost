class RtspUrlHelper {
  /// Returns a prioritised list of RTSP URLs to attempt for a given camera.
  /// Tries manufacturer-specific paths first, then generic fallbacks.
  static List<String> urlsToTry(
    String ip,
    int port, {
    String? username,
    String? password,
    String? manufacturer,
  }) {
    final auth = (username != null && username.isNotEmpty)
        ? '$username:${password ?? ''}@'
        : '';
    final base = 'rtsp://$auth$ip:$port';

    final manufacturerPaths = <String>[];
    final mfr = (manufacturer ?? '').toLowerCase();

    if (mfr.contains('hikvision')) {
      manufacturerPaths.addAll([
        '$base/Streaming/Channels/101',
        '$base/Streaming/Channels/1',
        '$base/Streaming/Channels/201',
      ]);
    } else if (mfr.contains('dahua')) {
      manufacturerPaths.addAll([
        '$base/cam/realmonitor?channel=1&subtype=0',
        '$base/cam/realmonitor?channel=1&subtype=1',
      ]);
    } else if (mfr.contains('axis')) {
      manufacturerPaths.addAll([
        '$base/axis-media/media.amp',
        '$base/mpeg4/media.amp',
      ]);
    }

    final generic = [
      '$base/',
      '$base/live',
      '$base/live.sdp',
      '$base/stream',
      '$base/stream1',
      '$base/video1',
      '$base/video.h264',
      '$base/h264',
      '$base/h264Preview_01_main',
      '$base/live/ch00_0',
      '$base/live/ch00_1',
      '$base/onvif/profile1/media.smp',
    ];

    return [...manufacturerPaths, ...generic];
  }

  /// Format a display-friendly URL (hides password)
  static String displayUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.userInfo.isNotEmpty) {
        final parts = uri.userInfo.split(':');
        final masked = '${parts[0]}:***';
        return url.replaceFirst(uri.userInfo, masked);
      }
    } catch (_) {}
    return url;
  }
}
