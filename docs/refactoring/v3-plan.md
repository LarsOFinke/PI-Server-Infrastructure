# Refactoring v3 – Feature-basiertes Setup

## Ziel

Das Setup soll nicht mehr über technische Schritt-Flags gesteuert werden, sondern über fachliche Features.

## Kernideen

- interaktive Feature-Auswahl direkt zu Beginn von `setup.sh`
- klare Features statt `--dev`, `--only` und `--skip`
- optionale Profile für nicht-interaktive Nutzung
- gezielte Container-Auswahl über Feature-Mapping

## Ergebnis

- `setup.sh` bleibt schlank und orchestriert nur noch auf Feature-Ebene
- der tägliche Workflow läuft über `scripts/services/`
- einzelne Bereiche wie Monitoring oder Postgres lassen sich separat neu einrichten
- Legacy-Wrapper und alte Schritt-Flags entfallen vollständig
