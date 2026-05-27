// server.js
const express = require('express');
const path = require('path');
const { exec } = require('child_process');

const app = express();
const PORT = process.env.PORT || 3000;

// Serve React build static files
app.use(express.static(path.join(__dirname, 'build')));

// API endpoint to run Vagrant commands (example)
app.get('/api/vagrant/up', (req, res) => {
  exec('vagrant up', { cwd: path.join(__dirname, '..', '..') }, (error, stdout, stderr) => {
    if (error) {
      console.error(`vagrant up error: ${error}`);
      return res.status(500).json({ error: error.message, stderr });
    }
    res.json({ message: 'Cluster started', stdout });
  });
});

// All other routes serve the React app
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Orbit-Cloud UI listening on http://localhost:${PORT}`);
});
