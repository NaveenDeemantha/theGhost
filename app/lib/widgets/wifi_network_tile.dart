import 'package:flutter/material.dart';
import '../models/wifi_network.dart';

class WifiNetworkTile extends StatelessWidget {
  final WifiNetwork network;

  const WifiNetworkTile({super.key, required this.network});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Icon(
            _wifiIcon(network.signalBars),
            color: network.isConnected ? colorScheme.primary : null,
            size: 32,
          ),
          if (network.isConnected)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 1.5),
              ),
            ),
        ],
      ),
      title: Text(
        network.ssid.isEmpty ? '(Hidden Network)' : network.ssid,
        style: TextStyle(
          fontWeight: network.isConnected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '${network.encryption} · ${network.frequency >= 5000 ? "5 GHz" : "2.4 GHz"} · ${network.signalLabel}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        '${network.signalStrength} dBm',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
      ),
    );
  }

  IconData _wifiIcon(int bars) {
    switch (bars) {
      case 4:
        return Icons.signal_wifi_4_bar;
      case 3:
        return Icons.network_wifi_3_bar;
      case 2:
        return Icons.network_wifi_2_bar;
      default:
        return Icons.network_wifi_1_bar;
    }
  }
}
