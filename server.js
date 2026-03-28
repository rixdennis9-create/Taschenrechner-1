'use strict';

require('dotenv').config();
const express = require('express');
const path    = require('path');

const app  = express();
const PORT = process.env.PORT || 3000;
const API_KEY = process.env.OPENAI_API_KEY;

/* ── Startup check ──────────────────────────────────── */
if (!API_KEY || !API_KEY.startsWith('sk-')) {
  console.warn('');
  console.warn('⚠️   OPENAI_API_KEY fehlt oder ist ungültig.');
  console.warn('    Online-KI ist deaktiviert – Offline-KI funktioniert weiterhin.');
  console.warn('    Für Online-Modus: Kopiere .env.example → .env und trage deinen Schlüssel ein.');
  console.warn('    https://platform.openai.com/api-keys');
  console.warn('');
} else {
  console.log('🔑  OpenAI API-Key gefunden – Online-KI aktiv.');
}

/* ── Middleware ─────────────────────────────────────── */
app.use(express.json({ limit: '8mb' }));

// Statische Dateien (index.html) aus dem gleichen Verzeichnis
app.use(express.static(path.join(__dirname)));

/* ══════════════════════════════════════════════════════
   OFFLINE-KI — Keine externen APIs, vollständig lokal
   ══════════════════════════════════════════════════════ */

// Gedächtnis: maximal 10 Einträge (= 5 vollständige Austausche)
const offlineMemory = [];

/**
 * Sicheres Berechnen eines mathematischen Ausdrucks.
 * Erlaubt nur Ziffern, Operatoren und Klammern – kein beliebiger Code.
 */
function safeCalc(expr) {
  try {
    const clean = expr.replace(/,/g, '.').replace(/\^/g, '**').trim();
    if (!/^[\d\s\+\-\*\/\(\)\.\%\*]+$/.test(clean)) return null;
    // eslint-disable-next-line no-new-func
    const result = new Function('"use strict"; return (' + clean + ')')();
    if (typeof result !== 'number' || !isFinite(result)) return null;
    // Auf sinnvolle Dezimalstellen runden
    return parseFloat(result.toPrecision(10));
  } catch (e) {
    return null;
  }
}

/**
 * Haupt-Logik der Offline-KI.
 * Prüft Muster der Reihe nach und gibt eine passende Antwort zurück.
 */
function generateOfflineReply(text, memory) {
  const t = text.trim();
  const lower = t.toLowerCase();

  // ── 1. Mathe-Erkennung ─────────────────────────────
  // Leerzeichen und Operatoren bereinigen, dann prüfen ob es eine Rechnung ist
  const mathCandidate = t.replace(/\s/g, '');
  if (/^[\d\+\-\*\/\(\)\.\,\^\%]+$/.test(mathCandidate) && /\d/.test(mathCandidate)) {
    const result = safeCalc(mathCandidate);
    if (result !== null) {
      return `🤖 Ergebnis: **${result}**\n\n💡 Rechnung: ${t} = ${result}`;
    }
  }

  // ── 2. Begrüßung ───────────────────────────────────
  if (/^(hi|hallo|hey|guten morgen|guten tag|moin|servus|nabend|tach)/i.test(lower)) {
    const greetings = [
      '👋 Hey! Schön, dass du da bist! Ich bin deine Offline-KI – kein Internet nötig. Was kann ich für dich tun? 😄',
      '🤖 Hallo! Ich bin bereit! Du kannst mich Mathe-Aufgaben lösen lassen oder einfach plaudern. Was ist dein Wunsch?',
      '😊 Hi! Willkommen im Offline-Modus! Ich funktioniere komplett ohne API-Key. Wie kann ich helfen?',
      '👋 Moin! Deine lokale KI ist aktiv. Stell mir eine Frage oder gib eine Rechnung ein – ich bin gespannt! 🚀'
    ];
    return greetings[Math.floor(Math.random() * greetings.length)];
  }

  // ── 3. Wie geht es ─────────────────────────────────
  if (/wie geht|wie läuft|wie bist du|alles gut/i.test(lower)) {
    return '😄 Mir geht\'s super! Ich laufe vollständig offline – kein Server-Stress, keine API-Kosten. Danke der Nachfrage! 💪 Was kann ich für dich rechnen oder beantworten?';
  }

  // ── 4. Hilfe ───────────────────────────────────────
  if (/hilfe|help|was kannst|was machst|fähigkeiten|können sie/i.test(lower)) {
    return '💡 **Ich bin die Offline-KI von DRX Studios!**\n\nIch kann:\n• 🧮 **Mathe rechnen** – gib einfach z.B. `2+2` oder `10*3-5` ein\n• 💬 **Plaudern** – Smalltalk auf Deutsch\n• 🧠 **Vorherige Nachrichten merken** – ich erinnere mich an die letzten 5 Austausche\n• ❓ **Fragen beantworten** – zu allgemeinen Themen\n\n🔌 Ich arbeite **ohne Internet** und **ohne API-Key**!';
  }

  // ── 5. Danke ───────────────────────────────────────
  if (/danke|thank|thx|dankeschön|merci/i.test(lower)) {
    const thanks = [
      'Gerne! 😊 Immer wieder! Wenn du noch etwas brauchst, einfach fragen.',
      '🤖 Kein Problem! Das ist genau mein Job. Noch eine Frage?',
      '✨ Sehr gerne! Es macht mir Spaß zu helfen. Was kommt als nächstes?'
    ];
    return thanks[Math.floor(Math.random() * thanks.length)];
  }

  // ── 6. Tschüss / Auf Wiedersehen ──────────────────
  if (/tschüss|bye|ciao|auf wiedersehen|bis dann|bis bald/i.test(lower)) {
    return '👋 Bis bald! War schön mit dir zu plaudern. Die Offline-KI ist jederzeit wieder für dich da! 🤖✨';
  }

  // ── 7. Wer bist du ─────────────────────────────────
  if (/wer bist|wer du|bist du eine|was bist du|stell dich vor/i.test(lower)) {
    return '🤖 Ich bin die **Offline-KI** von **DRX Studios** – eingebaut in den Dennis Pro Rechner!\n\nIch funktioniere **komplett ohne Internet** und ohne externen API-Key. Meine Antworten kommen direkt vom lokalen Server.\n\nFür komplexere Fragen kannst du in den 🌐 Online-Modus wechseln (benötigt einen OpenAI API-Key).';
  }

  // ── 8. Ja / Nein ───────────────────────────────────
  if (/^(ja|nein|ok|okay|klar|natürlich|genau|stimmt|richtig|falsch)$/i.test(lower)) {
    return '👍 Verstanden! Wie kann ich dir weiterhelfen?';
  }

  // ── 9. Gedächtnis-Referenz (30% Chance wenn genug Verlauf) ───
  const userMessages = memory.filter(m => m.role === 'user');
  if (userMessages.length >= 3 && Math.random() < 0.30) {
    const earlier = userMessages[userMessages.length - 2]; // vorletzte User-Nachricht
    if (earlier && earlier.content !== t) {
      return `💭 Du hast vorhin geschrieben: *"${earlier.content.slice(0, 60)}${earlier.content.length > 60 ? '…' : ''}"*\n\nDarauf aufbauend: Ich erinnere mich an unsere Unterhaltung! 🧠 Was möchtest du jetzt wissen?`;
    }
  }

  // ── 10. Fallback ───────────────────────────────────
  const fallbacks = [
    '🤔 Hmm, das ist eine interessante Frage! Für komplexe Antworten empfehle ich den 🌐 Online-Modus mit OpenAI. Im Offline-Modus bin ich auf Mathe und einfache Gespräche spezialisiert.',
    '💬 Das übersteigt meine Offline-Fähigkeiten ein bisschen! Probiere es mit einer **Mathe-Aufgabe** (z.B. `15*4`) oder wechsle in den 🌐 Online-Modus.',
    '🔌 Ich bin die Offline-KI und gebe mein Bestes! Für diese Frage bin ich leider nicht ausgestattet. Tipp: Versuche eine Rechnung einzugeben!',
    '😅 Gute Frage! Als Offline-KI habe ich begrenzte Kenntnisse. Frag mich gerne etwas zum Rechnen – da bin ich wirklich stark! 🧮',
    '🤖 Interessant! Ich merke mir das für später. 💭 Im Moment kann ich dir am besten bei **Mathe-Rechnungen** helfen. Was soll ich ausrechnen?'
  ];
  return fallbacks[Math.floor(Math.random() * fallbacks.length)];
}

/* ── POST /api/offline-chat ─────────────────────────── */
app.post('/api/offline-chat', (req, res) => {
  const { message } = req.body;
  if (!message || typeof message !== 'string') {
    return res.status(400).json({ error: 'Keine Nachricht angegeben.' });
  }
  const text = message.trim().slice(0, 2000);
  if (!text) return res.status(400).json({ error: 'Nachricht ist leer.' });

  // In Memory speichern (max. 10 Einträge)
  offlineMemory.push({ role: 'user', content: text });
  if (offlineMemory.length > 10) offlineMemory.splice(0, offlineMemory.length - 10);

  const reply = generateOfflineReply(text, offlineMemory);

  offlineMemory.push({ role: 'assistant', content: reply });
  if (offlineMemory.length > 10) offlineMemory.splice(0, offlineMemory.length - 10);

  res.json({ reply });
});

/* ══════════════════════════════════════════════════════
   ONLINE-KI — OpenAI API (benötigt OPENAI_API_KEY)
   ══════════════════════════════════════════════════════ */

/* ── POST /api/chat ─────────────────────────────────── */
app.post('/api/chat', async (req, res) => {
  // Online-Modus ohne API-Key: sinnvolle Fehlermeldung
  if (!API_KEY || !API_KEY.startsWith('sk-')) {
    return res.status(503).json({
      error: 'Online-KI nicht verfügbar: OPENAI_API_KEY fehlt. Bitte .env konfigurieren oder Offline-Modus verwenden.'
    });
  }

  const { model, messages, system } = req.body;

  if (!Array.isArray(messages) || messages.length === 0) {
    return res.status(400).json({ error: 'messages fehlt oder ist leer.' });
  }

  const ALLOWED_MODELS = ['gpt-4o-mini', 'gpt-4o', 'gpt-4-turbo'];
  const selectedModel = ALLOWED_MODELS.includes(model) ? model : 'gpt-4o-mini';

  const openaiMessages = [];
  if (typeof system === 'string' && system.trim()) {
    openaiMessages.push({ role: 'system', content: system.slice(0, 4000) });
  }

  for (const m of messages) {
    const role = m.role === 'assistant' ? 'assistant' : 'user';
    if (Array.isArray(m.content)) {
      const parts = m.content.map(part => {
        if (part.type === 'text') {
          return { type: 'text', text: String(part.text || '').slice(0, 8000) };
        }
        if (part.type === 'image' && part.source && part.source.type === 'base64') {
          const mt = part.source.media_type || 'image/jpeg';
          return { type: 'image_url', image_url: { url: `data:${mt};base64,${part.source.data}` } };
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
  console.log('🔌  Offline-KI: immer aktiv (kein API-Key nötig)');
  if (API_KEY && API_KEY.startsWith('sk-')) {
    console.log('🌐  Online-KI:  aktiv (OpenAI)');
  } else {
    console.log('🌐  Online-KI:  inaktiv (OPENAI_API_KEY fehlt)');
  }
  console.log('');
});
