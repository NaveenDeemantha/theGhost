import 'package:flutter/material.dart';

class ConnectedNetworkCard extends StatelessWidget {
  final Map<String, String?> info;

  const ConnectedNetworkCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final ssid = info['ssid']?.replaceAll('"', '') ?? 'Not connected';
    final ip = info['ip'] ?? '--';
    final gateway = info['gateway'] ?? '--';
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Connected Network',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ssid,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoChip(label: 'IP', value: ip),
                const SizedBox(width: 8),
                _InfoChip(label: 'Gateway', value: gateway),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(180),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
