import 'package:flutter/material.dart';
import '../models/wifi_network.dart';
import '../main.dart';
import 'connect_network_dialog.dart';

class WifiNetworkTile extends StatelessWidget {
  final WifiNetwork network;
  final VoidCallback? onConnected;

  const WifiNetworkTile({super.key, required this.network, this.onConnected});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleTap(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: network.isConnected ? kNavyLight : kNavy,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: network.isConnected ? kAccent : kNavyLight,
            width: network.isConnected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Signal icon
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Icon(
                  _wifiIcon(network.signalBars),
                  color: network.isConnected ? kAccent : const Color(0xFF5A7AAF),
                  size: 28,
                ),
                if (network.isConnected)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: kNavyLight, width: 1.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // SSID + details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          network.ssid.isEmpty ? '(Hidden Network)' : network.ssid,
                          style: TextStyle(
                            color: kWhite,
                            fontWeight: network.isConnected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (network.isConnected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Connected',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _SmallChip(
                          label: network.encryption,
                          color: _encryptionColor(network.encryption)),
                      _SmallChip(
                          label: network.frequency >= 5000 ? '5 GHz' : '2.4 GHz',
                          color: const Color(0xFF5A7AAF)),
                      if (network.hasWps)
                        _SmallChip(
                            label: 'WPS',
                            color: Colors.orange,
                            icon: Icons.warning_amber_rounded),
                      Text('${network.signalStrength} dBm',
                          style: const TextStyle(
                              color: Color(0xFF8AAAD4), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              network.isConnected ? Icons.check_circle : Icons.chevron_right,
              color: network.isConnected ? Colors.green : const Color(0xFF5A7AAF),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    if (network.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Already connected to "${network.ssid}"')),
      );
      return;
    }

    final connected =
        await ConnectNetworkDialog.show(context, network);
    if (connected && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to "${network.ssid}"'),
          backgroundColor: Colors.green.shade800,
        ),
      );
      onConnected?.call();
    }
  }

  Color _encryptionColor(String enc) {
    switch (enc.toUpperCase()) {
      case 'OPEN': return Colors.green;
      case 'WEP': return Colors.orange;
      case 'WPA3': return kAccent;
      default: return const Color(0xFF5A7AAF);
    }
  }

  IconData _wifiIcon(int bars) {
    switch (bars) {
      case 4: return Icons.signal_wifi_4_bar;
      case 3: return Icons.network_wifi_3_bar;
      case 2: return Icons.network_wifi_2_bar;
      default: return Icons.network_wifi_1_bar;
    }
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _SmallChip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: icon != null
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 3),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 10, fontWeight: FontWeight.w500)),
            ])
          : Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}
