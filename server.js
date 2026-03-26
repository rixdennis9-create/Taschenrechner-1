'use strict';

require('dotenv').config();
const express = require('express');
const path    = require('path');

const app  = express();
const PORT = process.env.PORT || 3000;
const API_KEY = process.env.ANTHROPIC_API_KEY;

/* ── Startup check ──────────────────────────────────── */
if (!API_KEY || !API_KEY.startsWith('sk-ant-')) {
  console.error('');
  console.error('❌  ANTHROPIC_API_KEY fehlt oder ist ungültig.');
  console.error('    1. Kopiere .env.example → .env');
  console.error('    2. Trage deinen Schlüssel in .env ein.');
  console.error('');
  process.exit(1);
}

/* ── Middleware ─────────────────────────────────────── */
app.use(express.json({ limit: '256kb' }));

// Statische Dateien (index.html) aus dem gleichen Verzeichnis
app.use(express.static(path.join(__dirname)));

/* ── POST /api/chat ─────────────────────────────────── */
app.post('/api/chat', async (req, res) => {
  const { model, messages, system } = req.body;

  // Eingabe-Validierung
  if (!Array.isArray(messages) || messages.length === 0) {
    return res.status(400).json({ error: 'messages fehlt oder ist leer.' });
  }

  const ALLOWED_MODELS = [
    'claude-haiku-4-5',
    'claude-sonnet-4-6',
    'claude-opus-4-6'
  ];
  const selectedModel = ALLOWED_MODELS.includes(model) ? model : 'claude-haiku-4-5';

  // Nachrichten bereinigen – nur role + content (string) zulassen
  const safeMessages = messages.map(m => ({
    role:    m.role === 'assistant' ? 'assistant' : 'user',
    content: String(m.content).slice(0, 8000)          // max 8000 Zeichen pro Nachricht
  }));

  try {
    // Dynamischer import für node-fetch (ESM-Modul)
    const { default: fetch } = await import('node-fetch');

    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method:  'POST',
      headers: {
        'Content-Type':      'application/json',
        'x-api-key':         API_KEY,        // Key bleibt ausschließlich im Backend
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model:      selectedModel,
        max_tokens: 1024,
        system:     typeof system === 'string' ? system.slice(0, 4000) : undefined,
        messages:   safeMessages
      })
    });

    if (!response.ok) {
      const err = await response.json().catch(() => ({}));
      const msg = err?.error?.message || `Anthropic API Fehler ${response.status}`;
      // Statuscode weiterleiten, aber den API-Key nie in Fehlermeldungen
      return res.status(response.status).json({ error: msg });
    }

    const data = await response.json();

    // Nur relevante Felder ans Frontend senden – nie den raw Request inkl. Key
    res.json({
      content: data.content,
      usage:   data.usage,
      model:   data.model
    });

  } catch (err) {
    console.error('Server-Fehler:', err.message);
    res.status(500).json({ error: 'Interner Server-Fehler. Bitte erneut versuchen.' });
  }
});

/* ── Alle anderen Routen → index.html ───────────────── */
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

/* ── Server starten ─────────────────────────────────── */
app.listen(PORT, () => {
  console.log('');
  console.log('✅  Dennis Pro Rechner läuft!');
  console.log(`    → http://localhost:${PORT}`);
  console.log('');
  console.log('🔒  API-Key ist sicher im Backend – niemals im Frontend sichtbar.');
  console.log('');
});
