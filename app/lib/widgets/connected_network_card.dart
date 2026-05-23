import 'package:flutter/material.dart';
import '../main.dart';
import '../models/wifi_network.dart';
import 'wifi_qr_sheet.dart';

class ConnectedNetworkCard extends StatelessWidget {
  final Map<String, String?> info;
  final String encryption;
  final WifiNetwork? connectedNetwork;

  const ConnectedNetworkCard({
    super.key,
    required this.info,
    this.encryption = 'WPA2',
    this.connectedNetwork,
  });

  @override
  Widget build(BuildContext context) {
    final rawSsid = info['ssid'];
    final ssid = (rawSsid == null || rawSsid.isEmpty) ? null : rawSsid;
    final ip = info['ip'] ?? '--';
    final gateway = info['gateway'] ?? '--';
    final isConnected = ssid != null;

    final net = connectedNetwork;
    final signalStr = net != null ? '${net.signalStrength}dBm' : null;
    final distLabel = net?.distanceLabel;
    final channel = net != null && net.channel > 0 ? 'CH${net.channel}' : null;

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
                  width: 8,
                  height: 8,
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
                    onTap: () =>
                        WifiQrSheet.show(context, ssid: ssid, encryption: encryption),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(border: Border.all(color: kGreenDim)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_rounded, color: kGreen, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'SHARE',
                            style: TextStyle(
                                color: kGreen,
                                fontSize: 9,
                                fontFamily: 'monospace',
                                letterSpacing: 1),
                          ),
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
                      style: TextStyle(
                          color: kGrayText, fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                if (isConnected) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _TermChip(label: 'IP', value: ip),
                      _TermChip(label: 'GW', value: gateway),
                      _TermChip(label: 'ENC', value: encryption),
                      if (channel != null) _TermChip(label: 'CH', value: channel),
                      if (signalStr != null) _TermChip(label: 'RSSI', value: signalStr),
                    ],
                  ),
                  if (distLabel != null) ...[
                    const SizedBox(height: 10),
                    _DistanceBar(distanceLabel: distLabel, network: net!),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DistanceBar extends StatelessWidget {
  final String distanceLabel;
  final WifiNetwork network;
  const _DistanceBar({required this.distanceLabel, required this.network});

  @override
  Widget build(BuildContext context) {
    // Normalize distance for progress bar (0 = 1m, 1 = >100m)
    final d = network.estimatedDistanceMeters.clamp(1.0, 100.0);
    final progress = (d - 1.0) / 99.0;

    final Color barColor;
    if (d < 5) {
      barColor = kGreen;
    } else if (d < 20) {
      barColor = kCyan;
    } else if (d < 50) {
      barColor = kOrange;
    } else {
      barColor = kRed;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: kCyan.withAlpha(60)),
        color: kCyan.withAlpha(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.router_rounded, color: kCyan, size: 12),
              const SizedBox(width: 6),
              const Text(
                'ROUTER DISTANCE',
                style: TextStyle(
                  color: kCyan,
                  fontSize: 9,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                distanceLabel,
                style: const TextStyle(
                  color: kCyan,
                  fontSize: 13,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              value: 1.0 - progress,
              backgroundColor: kTerminalBorder,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '1m',
                style: const TextStyle(
                    color: kDimText, fontSize: 8, fontFamily: 'monospace'),
              ),
              const Spacer(),
              Text(
                '${network.signalLabel.toUpperCase()} SIGNAL',
                style: TextStyle(
                    color: barColor, fontSize: 8, fontFamily: 'monospace'),
              ),
              const Spacer(),
              Text(
                '>100m',
                style: const TextStyle(
                    color: kDimText, fontSize: 8, fontFamily: 'monospace'),
              ),
            ],
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
            TextSpan(
                text: '$label:', style: const TextStyle(color: kGrayText)),
            TextSpan(text: value, style: const TextStyle(color: kGreen)),
          ],
        ),
      ),
    );
  }
}
