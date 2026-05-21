CREATE DATABASE IF NOT EXISTS theghost;
USE theghost;

CREATE TABLE IF NOT EXISTS wifi_networks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ssid VARCHAR(255) NOT NULL,
    bssid VARCHAR(17) NOT NULL,
    signal_strength INT,
    encryption VARCHAR(50),
    frequency INT,
    scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS scan_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    connected_ssid VARCHAR(255),
    connected_bssid VARCHAR(17),
    connected_ip VARCHAR(15),
    scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS network_devices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id INT,
    ip_address VARCHAR(15) NOT NULL,
    mac_address VARCHAR(17),
    manufacturer VARCHAR(255),
    hostname VARCHAR(255),
    open_ports JSON,
    is_camera BOOLEAN DEFAULT FALSE,
    camera_confidence VARCHAR(50),
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES scan_sessions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS camera_devices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id INT,
    ip_address VARCHAR(15) NOT NULL,
    mac_address VARCHAR(17),
    manufacturer VARCHAR(255),
    rtsp_port INT,
    http_port INT,
    onvif_detected BOOLEAN DEFAULT FALSE,
    network_ssid VARCHAR(255),
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES network_devices(id) ON DELETE CASCADE
);
