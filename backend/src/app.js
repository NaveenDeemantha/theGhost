const express = require('express');
const cors = require('cors');
require('dotenv').config();

const networksRouter = require('./routes/networks');
const sessionsRouter = require('./routes/sessions');
const devicesRouter = require('./routes/devices');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use('/api/networks', networksRouter);
app.use('/api/sessions', sessionsRouter);
app.use('/api/devices', devicesRouter);

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`TheGhost API running on port ${PORT}`);
});
