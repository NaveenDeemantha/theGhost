import 'package:flutter/material.dart';
import '../models/network_device.dart';
import '../models/device_type.dart';
import '../main.dart';

class DeviceTile extends StatelessWidget {
  final NetworkDevice device;
  const DeviceTile({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final isCamera = device.isCamera;
    final isNew = device.isNew;
    final accentColor = isCamera ? kOrange : kGreen;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: kTerminalCard,
        border: Border(
          left: BorderSide(color: accentColor, width: 3),
          top: BorderSide(color: kTerminalBorder),
          right: BorderSide(color: kTerminalBorder),
          bottom: BorderSide(color: kTerminalBorder),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(device.deviceType.icon,
                color: accentColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      device.ipAddress,
                      style: TextStyle(
                          color: isCamera ? kOrange : kGreen,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(border: Border.all(color: kCyan)),
                        child: const Text('NEW',
                            style: TextStyle(color: kCyan, fontSize: 9,
                                fontFamily: 'monospace', letterSpacing: 1)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    device.deviceType.label.toUpperCase(),
                    style: TextStyle(
                        color: accentColor.withAlpha(180),
                        fontSize: 10,
                        fontFamily: 'monospace',
                        letterSpacing: 1),
                  ),
                  if (device.hostname != null)
                    Text(device.hostname!,
                        style: const TextStyle(
                            color: kGrayText, fontSize: 10, fontFamily: 'monospace')),
                  if (device.openPorts.isNotEmpty)
                    Text(
                      'PORTS: ${device.openPorts.join("  ")}',
                      style: const TextStyle(
                          color: kDimText, fontSize: 10, fontFamily: 'monospace'),
                    ),
                  if (isCamera)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(children: [
                        const Icon(Icons.warning_rounded, size: 11, color: kOrange),
                        const SizedBox(width: 4),
                        Text(
                          'CAMERA DETECTED  [${(device.cameraConfidence ?? "").toUpperCase()}]',
                          style: const TextStyle(
                              color: kOrange, fontSize: 10,
                              fontFamily: 'monospace', letterSpacing: 0.5),
                        ),
                      ]),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: kDimText, size: 14),
          ],
        ),
      ),
    );
  }
}
