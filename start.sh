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

# npm install (nur wenn node_modules fehlt oder veraltet)
if [ ! -d "node_modules" ]; then
  echo "📦 Installiere Abhängigkeiten (einmalig)..."
  npm install --silent
  echo "✅ Abhängigkeiten installiert."
else
  echo "📦 Abhängigkeiten bereits vorhanden."
fi

echo ""
echo "🚀 Starte Server auf http://localhost:3000 ..."
node server.js &
SERVER_PID=$!

# Kurz warten bis der Server hochgefahren ist
sleep 1.5

# Browser öffnen — plattformübergreifend
if command -v xdg-open &>/dev/null; then
  # Linux
  xdg-open "http://localhost:3000" &>/dev/null &
elif command -v open &>/dev/null; then
  # macOS
  open "http://localhost:3000"
elif command -v cmd.exe &>/dev/null; then
  # Windows WSL
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
