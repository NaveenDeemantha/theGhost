import 'package:flutter/material.dart';

enum DeviceType {
  camera,
  router,
  printer,
  nas,
  smartTv,
  computer,
  iotDevice,
  unknown,
}

extension DeviceTypeExtension on DeviceType {
  String get label {
    switch (this) {
      case DeviceType.camera:
        return 'IP Camera';
      case DeviceType.router:
        return 'Router / Gateway';
      case DeviceType.printer:
        return 'Printer';
      case DeviceType.nas:
        return 'NAS / Storage';
      case DeviceType.smartTv:
        return 'Smart TV';
      case DeviceType.computer:
        return 'Computer / Server';
      case DeviceType.iotDevice:
        return 'IoT Device';
      case DeviceType.unknown:
        return 'Unknown Device';
    }
  }

  IconData get icon {
    switch (this) {
      case DeviceType.camera:
        return Icons.videocam;
      case DeviceType.router:
        return Icons.router;
      case DeviceType.printer:
        return Icons.print;
      case DeviceType.nas:
        return Icons.storage;
      case DeviceType.smartTv:
        return Icons.tv;
      case DeviceType.computer:
        return Icons.computer;
      case DeviceType.iotDevice:
        return Icons.device_hub;
      case DeviceType.unknown:
        return Icons.devices_other;
    }
  }

  String get toJson => name;

  static DeviceType fromJson(String? value) {
    return DeviceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeviceType.unknown,
    );
  }
}
