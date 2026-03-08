# Refactoring v5

## Ziel

Nach mehreren Refactorings gab es noch zu viele kleine Wrapper-Skripte und doppelte Shell-Logik.

Refactoring v5 reduziert das Repo auf:

- wenige echte Benutzer-Kommandos
- zentrale Libraries in `scripts/lib/`
- keine internen Setup-Mini-Wrapper mehr

## Umgesetzt

- `scripts/common/` entfernt und durch `scripts/lib/` ersetzt
- `scripts/setup/` entfernt
- `setup.sh` nutzt nur noch zentrale Library-Funktionen
- `services/*.sh` führen echte Compose-Kommandos direkt über Libraries aus
- Backup-Logik in `scripts/lib/backup.sh` zentralisiert
- doppelte Wrapper wie `start-infra.sh`, `show-status.sh`, `prepare-data-dirs.sh`, `prepare-backups.sh`, `validate-compose.sh`, `preflight.sh`, `post-check.sh` entfernt

## Ergebnis

Das Repo ist kleiner, ruhiger und klarer getrennt:

- Libraries = wiederverwendbare Funktionen
- Commands = direkte Benutzer-Einstiegspunkte
