'use strict';

require('dotenv').config();
const express = require('express');
const path    = require('path');

const app  = express();
const PORT = process.env.PORT || 3000;
const API_KEY = process.env.OPENAI_API_KEY;

/* ── Startup check ──────────────────────────────────── */
if (!API_KEY || !API_KEY.startsWith('sk-')) {
  console.error('');
  console.error('❌  OPENAI_API_KEY fehlt oder ist ungültig.');
  console.error('    1. Kopiere .env.example → .env');
  console.error('    2. Trage deinen OpenAI-Schlüssel in .env ein.');
  console.error('       https://platform.openai.com/api-keys');
  console.error('');
  process.exit(1);
}

/* ── Middleware ─────────────────────────────────────── */
app.use(express.json({ limit: '8mb' }));

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
    'gpt-4o-mini',
    'gpt-4o',
    'gpt-4-turbo'
  ];
  const selectedModel = ALLOWED_MODELS.includes(model) ? model : 'gpt-4o-mini';

  // Nachrichten für OpenAI aufbereiten
  const openaiMessages = [];

  // System-Nachricht als erste Nachricht einfügen
  if (typeof system === 'string' && system.trim()) {
    openaiMessages.push({ role: 'system', content: system.slice(0, 4000) });
  }

  // Benutzer/Assistent-Nachrichten konvertieren
  for (const m of messages) {
    const role = m.role === 'assistant' ? 'assistant' : 'user';
    // Vision: content ist ein Array mit Bild- und Text-Teilen
    if (Array.isArray(m.content)) {
      const parts = m.content.map(part => {
        if (part.type === 'text') {
          return { type: 'text', text: String(part.text || '').slice(0, 8000) };
        }
        // Bild: Anthropic-Format → OpenAI-Format konvertieren
        if (part.type === 'image' && part.source && part.source.type === 'base64') {
          const mt = part.source.media_type || 'image/jpeg';
          return {
            type: 'image_url',
            image_url: { url: `data:${mt};base64,${part.source.data}` }
          };
        }
        return null;
      }).filter(Boolean);
      openaiMessages.push({ role, content: parts });
    } else {
      openaiMessages.push({ role, content: String(m.content).slice(0, 8000) });
    }
  }

  try {
    const { default: fetch } = await import('node-fetch');

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method:  'POST',
      headers: {
        'Content-Type':  'application/json',
        'Authorization': `Bearer ${API_KEY}`
      },
      body: JSON.stringify({
        model:      selectedModel,
        max_tokens: Math.min(parseInt(req.body.max_tokens) || 1024, 2000),
        messages:   openaiMessages
      })
    });

    if (!response.ok) {
      const err = await response.json().catch(() => ({}));
      const msg = err?.error?.message || `OpenAI API Fehler ${response.status}`;
      return res.status(response.status).json({ error: msg });
    }

    const data = await response.json();
    const replyText = data.choices?.[0]?.message?.content || '';

    // Antwort im Frontend-kompatiblen Format zurückgeben
    res.json({
      content: [{ type: 'text', text: replyText }],
      usage:   { output_tokens: data.usage?.completion_tokens },
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
  console.log('🔒  OpenAI API-Key ist sicher im Backend – niemals im Frontend sichtbar.');
  console.log('');
});
