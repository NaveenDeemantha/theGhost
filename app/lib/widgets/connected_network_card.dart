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
    final ssid = info['ssid']?.replaceAll('"', '') ?? 'Not connected';
    final ip = info['ip'] ?? '--';
    final gateway = info['gateway'] ?? '--';
    final isConnected = info['ssid'] != null;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kNavy, kNavyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAccent.withAlpha(80), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                    color: kAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Connected Network',
                          style: TextStyle(
                              color: kAccent,
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w500)),
                      Text(
                        ssid,
                        style: const TextStyle(
                            color: kWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // QR Share button
                if (isConnected)
                  Tooltip(
                    message: 'Share network QR',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => WifiQrSheet.show(
                        context,
                        ssid: ssid,
                        encryption: encryption,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kAccent.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kAccent.withAlpha(60)),
                        ),
                        child: const Icon(Icons.qr_code_rounded,
                            color: kAccent, size: 18),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _InfoChip(icon: Icons.computer_rounded, label: 'IP', value: ip),
                const SizedBox(width: 8),
                _InfoChip(
                    icon: Icons.router_rounded, label: 'Gateway', value: gateway),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kNavyDark.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kNavyLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: kAccent),
          const SizedBox(width: 4),
          Text('$label: $value',
              style: const TextStyle(
                  color: kOffWhite, fontSize: 11, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
