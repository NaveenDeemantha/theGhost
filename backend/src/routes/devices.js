const express = require('express');
const router = express.Router();
const db = require('../db');

// Save discovered devices from a session
router.post('/', async (req, res) => {
  const { sessionId, devices } = req.body;
  if (!devices || !Array.isArray(devices)) {
    return res.status(400).json({ error: 'devices array required' });
  }
  try {
    const savedDevices = [];

    for (const d of devices) {
      const [result] = await db.query(
        `INSERT INTO network_devices
         (session_id, ip_address, mac_address, manufacturer, hostname, open_ports, is_camera, camera_confidence, device_type)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          sessionId,
          d.ipAddress,
          d.macAddress,
          d.manufacturer,
          d.hostname,
          JSON.stringify(d.openPorts || []),
          d.isCamera,
          d.cameraConfidence,
          d.deviceType || 'unknown',
        ]
      );

      if (d.isCamera) {
        await db.query(
          `INSERT INTO camera_devices
           (device_id, ip_address, mac_address, manufacturer, rtsp_port, http_port, onvif_detected, network_ssid)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            result.insertId,
            d.ipAddress,
            d.macAddress,
            d.manufacturer,
            d.rtspPort,
            d.httpPort,
            d.onvifDetected,
            d.networkSsid,
          ]
        );
      }

      savedDevices.push(result.insertId);
    }

    res.json({ saved: savedDevices.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all cameras ever detected
router.get('/cameras', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM camera_devices ORDER BY detected_at DESC'
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get cameras for a specific network SSID
router.get('/cameras/network/:ssid', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM camera_devices WHERE network_ssid = ? ORDER BY detected_at DESC',
      [req.params.ssid]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get devices for a session
router.get('/session/:sessionId', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM network_devices WHERE session_id = ?',
      [req.params.sessionId]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
