#!/bin/bash
# ═══════════════════════════════════════════════
#  Dennis Pro Rechner — Server Launcher
#  Doppelklick oder: ./start.sh
# ═══════════════════════════════════════════════

# Immer ins Projektverzeichnis wechseln (egal wo gestartet)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║   Dennis Pro Rechner — DRX Studios   ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# Node.js prüfen
if ! command -v node &>/dev/null; then
  echo "❌ FEHLER: Node.js ist nicht installiert!"
  echo "   → https://nodejs.org herunterladen und installieren."
  echo ""
  read -p "Drücke Enter zum Beenden..."
  exit 1
fi

# npm prüfen
if ! command -v npm &>/dev/null; then
  echo "❌ FEHLER: npm ist nicht installiert!"
  echo "   → Node.js neu installieren (npm ist dabei enthalten)."
  echo ""
  read -p "Drücke Enter zum Beenden..."
  exit 1
fi

# Abhängigkeiten immer prüfen und installieren
echo "📦 Prüfe Abhängigkeiten..."
npm install
if [ $? -ne 0 ]; then
  echo ""
  echo "❌ FEHLER: npm install fehlgeschlagen!"
  echo "   Stelle sicher, dass du eine Internetverbindung hast."
  echo ""
  read -p "Drücke Enter zum Beenden..."
  exit 1
fi
echo "✅ Alle Abhängigkeiten bereit."

echo ""
echo "🚀 Starte Server auf http://localhost:3000 ..."
node server.js &
SERVER_PID=$!

# Warten bis der Server hochgefahren ist
sleep 2

# Prüfen ob der Server wirklich läuft
if ! kill -0 $SERVER_PID 2>/dev/null; then
  echo ""
  echo "❌ FEHLER: Server konnte nicht gestartet werden!"
  echo "   Prüfe deine .env Datei (OPENAI_API_KEY)."
  echo ""
  read -p "Drücke Enter zum Beenden..."
  exit 1
fi

# Browser öffnen — plattformübergreifend
if command -v xdg-open &>/dev/null; then
  xdg-open "http://localhost:3000" &>/dev/null &
elif command -v open &>/dev/null; then
  open "http://localhost:3000"
elif command -v cmd.exe &>/dev/null; then
  cmd.exe /c start "http://localhost:3000" &>/dev/null
else
  echo ""
  echo "  ➡️  Öffne im Browser: http://localhost:3000"
fi

echo ""
echo "  ✅ Server läuft (PID $SERVER_PID)"
echo "  🌐 App:  http://localhost:3000"
echo "  ⏹  Zum Beenden: Ctrl + C"
echo ""

# Warten bis der Nutzer Ctrl+C drückt
trap "echo ''; echo '🛑 Server wird gestoppt...'; kill $SERVER_PID 2>/dev/null; exit 0" SIGINT SIGTERM
wait $SERVER_PID
