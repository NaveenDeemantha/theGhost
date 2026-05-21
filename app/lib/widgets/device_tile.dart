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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCamera
            ? const Color(0xFF2A1A1F)
            : kNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCamera
              ? kErrorRed.withAlpha(120)
              : isNew
                  ? Colors.green.withAlpha(120)
                  : kNavyLight,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCamera
                ? kErrorRed.withAlpha(30)
                : kAccent.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            device.deviceType.icon,
            color: isCamera ? kErrorRed : kAccent,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Text(
              device.ipAddress,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: kWhite,
                  fontSize: 14),
            ),
            if (isNew) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('NEW',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.deviceType.label,
                style: TextStyle(
                    color: isCamera ? kErrorRed : kAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            if (device.hostname != null)
              Text(device.hostname!,
                  style: const TextStyle(color: Color(0xFF8AAAD4), fontSize: 11)),
            if (device.openPorts.isNotEmpty)
              Text(
                'Ports: ${device.openPorts.join(", ")}',
                style: const TextStyle(color: Color(0xFF8AAAD4), fontSize: 11),
              ),
            if (isCamera)
              Row(
                children: [
                  const Icon(Icons.warning_amber, size: 12, color: kErrorRed),
                  const SizedBox(width: 4),
                  Text(
                    'Camera · ${device.cameraConfidence ?? ""} confidence',
                    style: const TextStyle(
                        color: kErrorRed,
                        fontWeight: FontWeight.w500,
                        fontSize: 11),
                  ),
                ],
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF5A7AAF), size: 18),
        isThreeLine: true,
      ),
    );
  }
}
