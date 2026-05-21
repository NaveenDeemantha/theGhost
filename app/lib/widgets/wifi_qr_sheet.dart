import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../main.dart';

class WifiQrSheet extends StatefulWidget {
  final String ssid;
  final String encryption;

  const WifiQrSheet({super.key, required this.ssid, required this.encryption});

  static Future<void> show(BuildContext context,
      {required String ssid, required String encryption}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WifiQrSheet(ssid: ssid, encryption: encryption),
    );
  }

  @override
  State<WifiQrSheet> createState() => _WifiQrSheetState();
}

class _WifiQrSheetState extends State<WifiQrSheet> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _showQr = false;

  String get _qrData {
    final type = widget.encryption == 'Open'
        ? 'nopass'
        : widget.encryption == 'WEP'
            ? 'WEP'
            : 'WPA';
    final password = widget.encryption == 'Open'
        ? ''
        : 'P:${_escape(_passwordController.text)};';
    return 'WIFI:T:$type;S:${_escape(widget.ssid)};$password;';
  }

  // Escape special chars per WiFi QR spec
  String _escape(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('"', '\\"');

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = widget.encryption == 'Open';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: kNavyLight, borderRadius: BorderRadius.circular(2)),
            ),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_rounded, color: kAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Share Network',
                          style: TextStyle(
                              color: kWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text(widget.ssid,
                          style: const TextStyle(
                              color: Color(0xFF8AAAD4), fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kAccent.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kAccent.withAlpha(40)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: kAccent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This QR code lets another device join your network by scanning it — without seeing the password as text.',
                      style: TextStyle(
                          color: Color(0xFF8AAAD4), fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Password field (for secured networks)
            if (!isOpen && !_showQr) ...[
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                style: const TextStyle(color: kWhite),
                decoration: InputDecoration(
                  labelText: 'Your WiFi Password',
                  labelStyle: const TextStyle(color: Color(0xFF5A7AAF)),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF5A7AAF),
                        size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // QR Code display
            if (_showQr || isOpen) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: kWhite,
                  eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square, color: Color(0xFF0B1426)),
                  dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF0B1426)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Scan with camera to connect to "${widget.ssid}"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8AAAD4), fontSize: 12),
              ),
              const SizedBox(height: 8),
              // Copy QR string
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _qrData));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('WiFi config string copied')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF5A7AAF)),
                label: const Text('Copy config string',
                    style: TextStyle(color: Color(0xFF5A7AAF), fontSize: 12)),
              ),
            ],

            // Generate / reset button
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: _showQr && !isOpen
                  ? OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _showQr = false),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Change Password'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5A7AAF),
                          side: const BorderSide(color: kNavyLight)),
                    )
                  : isOpen
                      ? const SizedBox.shrink()
                      : FilledButton.icon(
                          onPressed: _passwordController.text.isEmpty
                              ? null
                              : () => setState(() => _showQr = true),
                          icon: const Icon(Icons.qr_code_rounded, size: 16),
                          label: const Text('Generate QR Code'),
                        ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
