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
  });

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
      };
}
