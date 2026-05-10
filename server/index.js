const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const SECRET_KEY = process.env.JWT_SECRET || 'super_secret_key_change_in_prod';

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(bodyParser.json());

// On Vercel, the filesystem is read-only except for /tmp.
// Use /tmp for the SQLite database (note: data is ephemeral per cold-start).
const DB_PATH = process.env.VERCEL
  ? '/tmp/daily_agenda.db'
  : path.join(__dirname, 'daily_agenda.db');

const db = new sqlite3.Database(DB_PATH, (err) => {
  if (err) console.error('DB connection error:', err.message);
  else console.log(`Connected to SQLite at ${DB_PATH}`);
});

db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE,
    password TEXT
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    userId INTEGER,
    title TEXT,
    description TEXT,
    categoryId TEXT,
    priority TEXT,
    startTime TEXT,
    endTime TEXT,
    isCompleted INTEGER,
    createdAt TEXT,
    FOREIGN KEY(userId) REFERENCES users(id)
  )`);
});

// ── Auth Middleware ──────────────────────────────────────────────────────────
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.sendStatus(401);

  jwt.verify(token, SECRET_KEY, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

// ── Routes ───────────────────────────────────────────────────────────────────
app.get('/', (_req, res) => {
  res.json({ status: 'ok', message: 'Daily Agenda API is running.' });
});

app.post('/register', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password)
    return res.status(400).json({ error: 'Username and password are required' });

  const hashedPassword = await bcrypt.hash(password, 10);
  db.run(
    `INSERT INTO users (username, password) VALUES (?, ?)`,
    [username, hashedPassword],
    function (err) {
      if (err) return res.status(400).json({ error: 'Username already exists' });
      res.json({ id: this.lastID });
    }
  );
});

app.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (!username || !password)
    return res.status(400).json({ error: 'Username and password are required' });

  db.get(`SELECT * FROM users WHERE username = ?`, [username], async (err, user) => {
    if (err || !user) return res.status(400).json({ error: 'User not found' });

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) return res.status(400).json({ error: 'Invalid password' });

    const token = jwt.sign({ id: user.id, username: user.username }, SECRET_KEY, {
      expiresIn: '7d',
    });
    res.json({ token });
  });
});

app.get('/tasks', authenticateToken, (req, res) => {
  db.all(`SELECT * FROM tasks WHERE userId = ?`, [req.user.id], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.post('/tasks', authenticateToken, (req, res) => {
  const t = req.body;
  db.run(
    `INSERT OR REPLACE INTO tasks
      (id, userId, title, description, categoryId, priority, startTime, endTime, isCompleted, createdAt)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [t.id, req.user.id, t.title, t.description, t.categoryId, t.priority,
     t.startTime, t.endTime, t.isCompleted ? 1 : 0, t.createdAt],
    (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true });
    }
  );
});

app.delete('/tasks/:id', authenticateToken, (req, res) => {
  db.run(
    `DELETE FROM tasks WHERE id = ? AND userId = ?`,
    [req.params.id, req.user.id],
    (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true });
    }
  );
});

app.get('/admin/users', (_req, res) => {
  db.all(`SELECT id, username FROM users`, [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

// ── Start (local dev) or Export (Vercel serverless) ─────────────────────────
if (process.env.VERCEL) {
  // Vercel calls this as a serverless function — just export the app
  module.exports = app;
} else {
  app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
  module.exports = app;
}
