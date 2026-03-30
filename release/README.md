# Download-Paket

Direkt-Download-Dateien:

- `vegas-casino-complete.html` wird **lokal aus `casino-game.html` erzeugt** (nicht im Git, um Merge-Konflikte zu vermeiden)
- `vegas-casino-complete.zip` wird **lokal erzeugt** (nicht im Git, damit kein Binärdiff entsteht)

Erstellt aus dem aktuellen Stand von `casino-game.html`.


In-App-Download:
- Im Hauptmenü auf **⬇️ Download** klicken, um die aktuelle HTML-Datei direkt herunterzuladen.


ZIP lokal erzeugen:
```bash
cd release
zip -q vegas-casino-complete.zip vegas-casino-complete.html
```


HTML lokal erzeugen:
```bash
cp casino-game.html release/vegas-casino-complete.html
```
