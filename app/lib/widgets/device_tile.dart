import 'package:flutter/material.dart';
import '../models/network_device.dart';

class DeviceTile extends StatelessWidget {
  final NetworkDevice device;

  const DeviceTile({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: device.isCamera ? colorScheme.errorContainer : null,
      child: ListTile(
        leading: Icon(
          device.isCamera ? Icons.videocam : Icons.devices,
          color: device.isCamera ? colorScheme.error : colorScheme.primary,
          size: 28,
        ),
        title: Text(
          device.ipAddress,
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (device.manufacturer != null)
              Text(device.manufacturer!, style: const TextStyle(fontWeight: FontWeight.w500)),
            if (device.hostname != null)
              Text(device.hostname!, style: Theme.of(context).textTheme.bodySmall),
            if (device.openPorts.isNotEmpty)
              Text(
                'Ports: ${device.openPorts.join(", ")}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (device.isCamera)
              Row(
                children: [
                  Icon(Icons.warning_amber, size: 14, color: colorScheme.error),
                  const SizedBox(width: 4),
                  Text(
                    'Camera detected · ${device.cameraConfidence ?? ""} confidence',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
