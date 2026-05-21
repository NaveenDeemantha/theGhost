const express = require('express');
const router = express.Router();
const db = require('../db');

// Create a new scan session (connected network info)
router.post('/', async (req, res) => {
  const { connectedSsid, connectedBssid, connectedIp } = req.body;
  try {
    const [result] = await db.query(
      'INSERT INTO scan_sessions (connected_ssid, connected_bssid, connected_ip) VALUES (?, ?, ?)',
      [connectedSsid, connectedBssid, connectedIp]
    );
    res.json({ sessionId: result.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all sessions
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM scan_sessions ORDER BY scanned_at DESC LIMIT 50'
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get devices from the most recent session for a given SSID
router.get('/last/:ssid', async (req, res) => {
  try {
    const [sessions] = await db.query(
      'SELECT id FROM scan_sessions WHERE connected_ssid = ? ORDER BY scanned_at DESC LIMIT 1',
      [req.params.ssid]
    );
    if (!sessions.length) return res.json([]);

    const [devices] = await db.query(
      'SELECT ip_address, device_type, is_camera FROM network_devices WHERE session_id = ?',
      [sessions[0].id]
    );
    res.json(devices);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
