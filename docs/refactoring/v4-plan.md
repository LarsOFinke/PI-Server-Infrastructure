# Refactoring v4 – Konsolidierung und Entdoppelung

## Ziel
Das Repo nach mehreren Refactorings aufräumen, doppelte Logik reduzieren und gemeinsame Hilfsfunktionen zentralisieren.

## Umgesetzt
- `scripts/common/checks.sh` eingeführt für wiederverwendbare Prüf- und Validierungslogik
- `preflight.sh` und `post-check.sh` auf gemeinsame Check-Funktionen umgestellt
- Backup-Skripte auf gemeinsame Env-/FS-Helfer vereinheitlicht
- `scripts/common/all.sh` auf aktiv genutzte Module reduziert
- ungenutzte Altdateien entfernt:
  - `scripts/common/paths.sh`
  - `scripts/common/steps.sh`
- Test-/Laufzeit-Logs aus dem Repo entfernt

## Ergebnis
- weniger doppelte Shell-Logik
- klarere Trennung zwischen Setup, Checks, Backup und Services
- geringere Wartungskosten für weitere Features
