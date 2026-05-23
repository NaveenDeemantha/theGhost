import 'package:flutter/material.dart';
import '../main.dart';
import 'wifi_qr_sheet.dart';

class ConnectedNetworkCard extends StatelessWidget {
  final Map<String, String?> info;
  final String encryption;

  const ConnectedNetworkCard({
    super.key,
    required this.info,
    this.encryption = 'WPA2',
  });

  @override
  Widget build(BuildContext context) {
    final rawSsid = info['ssid'];
    final ssid = (rawSsid == null || rawSsid.isEmpty) ? null : rawSsid;
    final ip = info['ip'] ?? '--';
    final gateway = info['gateway'] ?? '--';
    final isConnected = ssid != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: kTerminalCard,
        border: Border.all(color: isConnected ? kGreen : kRed, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            width: double.infinity,
            color: isConnected ? kGreenFaint : kRed.withAlpha(30),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: isConnected ? kGreen : kRed,
                    shape: BoxShape.circle,
                    boxShadow: isConnected
                        ? [BoxShadow(color: kGreen.withAlpha(120), blurRadius: 6)]
                        : [],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected ? 'CONNECTED' : 'NOT CONNECTED',
                  style: TextStyle(
                    color: isConnected ? kGreen : kRed,
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                if (isConnected)
                  GestureDetector(
                    onTap: () => WifiQrSheet.show(
                        context, ssid: ssid, encryption: encryption),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: kGreenDim),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_rounded, color: kGreen, size: 12),
                          SizedBox(width: 4),
                          Text('SHARE', style: TextStyle(
                              color: kGreen, fontSize: 9,
                              fontFamily: 'monospace', letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ssid ?? 'NO WIFI CONNECTION',
                  style: TextStyle(
                    color: isConnected ? kWhiteText : kRed,
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                if (!isConnected)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Enable WiFi and grant location permission',
                      style: TextStyle(color: kGrayText, fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                if (isConnected) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _TermChip(label: 'IP', value: ip),
                      const SizedBox(width: 8),
                      _TermChip(label: 'GW', value: gateway),
                      const SizedBox(width: 8),
                      _TermChip(label: 'ENC', value: encryption),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermChip extends StatelessWidget {
  final String label;
  final String value;
  const _TermChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: kGreenDim.withAlpha(120)),
        color: kGreenFaint,
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          children: [
            TextSpan(text: '$label:', style: const TextStyle(color: kGrayText)),
            TextSpan(text: value, style: const TextStyle(color: kGreen)),
          ],
        ),
      ),
    );
  }
}
