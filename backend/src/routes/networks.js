const express = require('express');
const router = express.Router();
const db = require('../db');

// Save scanned nearby networks
router.post('/scan', async (req, res) => {
  const { networks } = req.body;
  if (!networks || !Array.isArray(networks)) {
    return res.status(400).json({ error: 'networks array required' });
  }
  try {
    const values = networks.map(n => [
      n.ssid, n.bssid, n.signalStrength, n.encryption, n.frequency
    ]);
    await db.query(
      'INSERT INTO wifi_networks (ssid, bssid, signal_strength, encryption, frequency) VALUES ?',
      [values]
    );
    res.json({ saved: values.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get scan history
router.get('/history', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM wifi_networks ORDER BY scanned_at DESC LIMIT 100'
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
