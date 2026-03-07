# Refactoring v1 Plan

## Ziel

Das Repo soll nach dem ersten lauffähigen Stand in kleinere, klar getrennte Shell-Module zerlegt werden.

## Leitlinien

- KISS: kleine, gut benannte Skripte und Funktionen
- SRP: eine Datei, ein Hauptzweck
- geringe Kopplung zwischen Setup, Services und Backups
- Wiederverwendung gemeinsamer Hilfsfunktionen aus `scripts/common/`

## Ergebnis

- `setup.sh` orchestriert nur noch den Ablauf
- gemeinsame Logik liegt in `scripts/common/`
- Setup-Schritte liegen in `scripts/setup/`
- tägliche Docker-Arbeit liegt in `scripts/services/`
- Backup/Restore liegt in `scripts/backup/`
