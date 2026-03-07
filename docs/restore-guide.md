# Restore Guide

## Postgres wiederherstellen

1. Sicherstellen, dass der Stack läuft.
2. SQL-Backup-Datei auswählen.
3. Restore ausführen:

```bash
./scripts/backup/restore-postgres.sh /srv/backups/postgres/<datei>.sql
```

## Datenarchiv entpacken

```bash
tar -xzf /srv/backups/data/<archiv>.tar.gz
```

Vor einem Restore der `data/`-Ordner sollte der Stack gestoppt werden:

```bash
./scripts/services/stop.sh
```
