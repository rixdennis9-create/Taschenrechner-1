# ModMenu – Luanti / Minetest Mod

Ein in-game Mod Menu mit vielen nützlichen Features.

## Installation

1. Ordner `modmenu` in dein Luanti-Mod-Verzeichnis kopieren:
   - **Linux:** `~/.minetest/mods/`
   - **Windows:** `%APPDATA%\minetest\mods\`
2. Im Spiel: **Einstellungen → Mods → modmenu** aktivieren
3. Welt starten

## Nutzung

| Befehl | Beschreibung |
|--------|-------------|
| `/menu` | Mod Menu öffnen |
| `/mm`   | Kurzbefehl |

## Features

### Bewegung
- **Fliegen** – Toggle fly-Modus (benötigt `fly`-Privileg)
- **Noclip** – Durch Wände gehen (benötigt `noclip`-Privileg)
- **Schnell** – Schnelllauf (benötigt `fast`-Privileg)
- **Geschwindigkeit** – 0.5x bis 10x Bewegungsgeschwindigkeit

### Überleben
- **Unendliche HP** – Auto-Heilung bei Schaden
- **Jetzt heilen** – Sofort volle HP
- **Inventar füllen** – Inventar mit Blöcken füllen
- **Inventar leeren** – Inventar komplett leeren

### Teleport
- Zu beliebigen X/Y/Z-Koordinaten teleportieren
- Direkt zum Spawn springen

### Welt
- Zeit auf **Tag** (12:00) setzen
- Zeit auf **Nacht** (0:00) setzen

## Hinweis

Fly, Noclip und Fast benötigen die entsprechenden Server-Privilegien.  
Als Server-Admin kannst du dir diese selbst mit  
`/grant <dein_name> fly,noclip,fast`  
geben.
