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
    final isConnected = network.isConnected;
    final borderColor = isConnected ? kGreen : kTerminalBorder;

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: isConnected ? kGreenFaint : kTerminalCard,
          border: Border(
            left: BorderSide(
                color: isConnected ? kGreen : _encryptionColor(network.encryption),
                width: 3),
            top: BorderSide(color: borderColor),
            right: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Signal bars
            _SignalBars(bars: network.signalBars, isConnected: isConnected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          network.ssid.isEmpty ? '[HIDDEN]' : network.ssid,
                          style: TextStyle(
                            color: isConnected ? kGreen : kWhiteText,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isConnected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: kGreen),
                            color: kGreenFaint,
                          ),
                          child: const Text('ACTIVE',
                              style: TextStyle(
                                  color: kGreen, fontSize: 9,
                                  fontFamily: 'monospace', letterSpacing: 1.5)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 3,
                    children: [
                      _Tag(label: network.encryption, color: _encryptionColor(network.encryption)),
                      _Tag(label: network.frequency >= 5000 ? '5GHz' : '2.4GHz', color: kGrayText),
                      _Tag(label: '${network.signalStrength}dBm', color: kGrayText),
                      if (network.hasWps)
                        _Tag(label: 'WPS!', color: kOrange, blink: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isConnected ? Icons.check_rounded : Icons.chevron_right_rounded,
              color: isConnected ? kGreen : kGrayText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    if (network.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('> Already connected to "${network.ssid}"')),
      );
      return;
    }
    final connected = await ConnectNetworkDialog.show(context, network);
    if (connected && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('> Connected to "${network.ssid}"')),
      );
      onConnected?.call();
    }
  }

  Color _encryptionColor(String enc) {
    switch (enc.toUpperCase()) {
      case 'OPEN':   return Colors.green;
      case 'WEP':    return kOrange;
      case 'WPA3':   return kCyan;
      case 'WPA2':   return kGreenDim;
      default:       return kGrayText;
    }
  }
}

class _SignalBars extends StatelessWidget {
  final int bars;
  final bool isConnected;
  const _SignalBars({required this.bars, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? kGreen : kGreenDim;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < bars;
        return Container(
          width: 4,
          height: 4.0 + i * 3,
          margin: const EdgeInsets.only(right: 2),
          color: active ? color : kTerminalBorder,
        );
      }),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final bool blink;
  const _Tag({required this.label, required this.color, this.blink = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontFamily: 'monospace',
              letterSpacing: 0.5)),
    );
  }
}
