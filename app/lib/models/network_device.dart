import 'device_type.dart';

class NetworkDevice {
  final String ipAddress;
  final String? macAddress;
  final String? manufacturer;
  final String? hostname;
  final List<int> openPorts;
  final bool isCamera;
  final String? cameraConfidence;
  final int? rtspPort;
  final int? httpPort;
  final bool onvifDetected;
  final DeviceType deviceType;
  final bool isNew;

  NetworkDevice({
    required this.ipAddress,
    this.macAddress,
    this.manufacturer,
    this.hostname,
    this.openPorts = const [],
    this.isCamera = false,
    this.cameraConfidence,
    this.rtspPort,
    this.httpPort,
    this.onvifDetected = false,
    this.deviceType = DeviceType.unknown,
    this.isNew = false,
  });

  NetworkDevice copyWith({bool? isNew}) {
    return NetworkDevice(
      ipAddress: ipAddress,
      macAddress: macAddress,
      manufacturer: manufacturer,
      hostname: hostname,
      openPorts: openPorts,
      isCamera: isCamera,
      cameraConfidence: cameraConfidence,
      rtspPort: rtspPort,
      httpPort: httpPort,
      onvifDetected: onvifDetected,
      deviceType: deviceType,
      isNew: isNew ?? this.isNew,
    );
  }

  Map<String, dynamic> toJson() => {
        'ipAddress': ipAddress,
        'macAddress': macAddress,
        'manufacturer': manufacturer,
        'hostname': hostname,
        'openPorts': openPorts,
        'isCamera': isCamera,
        'cameraConfidence': cameraConfidence,
        'rtspPort': rtspPort,
        'httpPort': httpPort,
        'onvifDetected': onvifDetected,
        'deviceType': deviceType.toJson,
      };

  String get displayName {
    if (hostname != null && hostname!.isNotEmpty && hostname != ipAddress) {
      return hostname!;
    }
    if (manufacturer != null) return manufacturer!;
    return ipAddress;
  }
}
