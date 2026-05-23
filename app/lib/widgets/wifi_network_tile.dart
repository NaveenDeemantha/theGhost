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
    final isOpen = network.isOpen;

    final Color leftBorder;
    final Color bgColor;
    final Color borderColor;

    if (isConnected) {
      leftBorder = kGreen;
      bgColor = kGreenFaint;
      borderColor = kGreen;
    } else if (isOpen) {
      leftBorder = kRed;
      bgColor = kRed.withAlpha(15);
      borderColor = kRed.withAlpha(60);
    } else {
      leftBorder = _encryptionColor(network.encryption);
      bgColor = kTerminalCard;
      borderColor = kTerminalBorder;
    }

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            left: BorderSide(color: leftBorder, width: 3),
            top: BorderSide(color: borderColor),
            right: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _SignalBars(bars: network.signalBars, isConnected: isConnected, isOpen: isOpen),
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
                            color: isConnected ? kGreen : (isOpen ? kRed : kWhiteText),
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isConnected) _Badge('ACTIVE', kGreen, kGreenFaint),
                      if (isOpen && !isConnected) _Badge('OPEN!', kRed, kRed.withAlpha(20)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 3,
                    children: [
                      _Tag(
                        label: isOpen ? 'UNPROTECTED' : network.encryption,
                        color: _encryptionColor(network.encryption),
                      ),
                      _Tag(
                        label: network.frequency >= 5000 ? '5GHz' : '2.4GHz',
                        color: kGrayText,
                      ),
                      if (network.channel > 0)
                        _Tag(label: 'CH${network.channel}', color: kGrayText),
                      _Tag(label: '${network.signalStrength}dBm', color: kGrayText),
                      _Tag(
                        label: network.distanceLabel,
                        color: kCyan,
                        icon: Icons.straighten_rounded,
                      ),
                      if (network.hasWps) _Tag(label: 'WPS!', color: kOrange),
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
      case 'OPEN':
        return kRed;
      case 'WEP':
        return kOrange;
      case 'WPA3':
        return kCyan;
      case 'WPA2':
        return kGreenDim;
      default:
        return kGrayText;
    }
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  const _Badge(this.text, this.fg, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: fg),
        color: bg,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 9,
          fontFamily: 'monospace',
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final int bars;
  final bool isConnected;
  final bool isOpen;
  const _SignalBars({required this.bars, required this.isConnected, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? kGreen : (isOpen ? kRed : kGreenDim);
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
  final IconData? icon;
  const _Tag({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(border: Border.all(color: color.withAlpha(120))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 8, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
