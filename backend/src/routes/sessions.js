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

module.exports = router;
