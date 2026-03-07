# PI Server Infrastructure

Dieses Repo richtet die Basis-Infrastruktur auf einem Raspberry Pi oder Debian-Host ein. Nach Refactoring v1 ist das Repo in klar getrennte Bereiche aufgeteilt:

- `setup.sh` orchestriert nur noch den Ablauf
- `scripts/common/` enthält wiederverwendbare Hilfsfunktionen
- `scripts/setup/` enthält Setup-Schritte
- `scripts/services/` enthält tägliche Docker-Operationen
- `scripts/backup/` enthält Backup- und Restore-Skripte
- `scripts/legacy/` enthält historisch gewachsene Host-Skripte

## Architektur des Repos

```text
PI-Server-Infrastructure/
├── setup.sh
├── compose.yml
├── config/
│   └── env/
├── db/
├── docs/
├── nginx/
├── data/
├── logs/
└── scripts/
    ├── common/
    ├── setup/
    ├── services/
    ├── backup/
    └── legacy/
```

## Enthaltene Infrastruktur

- Nginx als Reverse Proxy
- Postgres als interne Datenbank
- Uptime Kuma als Monitoring
- Docker-Netzwerke für Frontend und Backend
- lokaler Postgres-Port auf `127.0.0.1:15432`
- Setup-Logging, Dev-Modus und selektive Schrittsteuerung
- Backup- und Restore-Skripte

## Einmaliger Ablauf auf einem frischen Pi

### 1. Pi vorbereiten

- Raspberry Pi OS / Debian installieren
- SSH aktivieren
- Netzwerk prüfen

### 2. Git einmalig einrichten

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y git
git config --global user.name "Dein Name"
git config --global user.email "deine-mail@example.com"
ssh-keygen -t ed25519 -C "deine-mail@example.com"
ssh -T git@github.com
```

### 3. Repo klonen

```bash
git clone <DEIN-REPO-URL> ~/repositories/server
cd ~/repositories/server
chmod +x setup.sh scripts/*.sh scripts/*/*.sh
```

### 4. `.env` anpassen

Beim ersten Lauf wird `.env` automatisch aus `.env.example` erstellt.
Pflichtschlüssel stehen in `config/env/required.env.keys`.

### 5. Komplettes Setup starten

```bash
./setup.sh
```

Mit Debug-Ausgabe:

```bash
DEBUG=true ./setup.sh
```

Mit interaktiver Bestätigung pro Schritt:

```bash
./setup.sh --dev
```

## Setup gezielt steuern

Nur bestimmte Schritte ausführen:

```bash
./setup.sh --only validate,start,status
```

Bestimmte Schritte überspringen:

```bash
./setup.sh --skip bootstrap,preflight
```

Container beim Setup nicht starten:

```bash
./setup.sh --no-start
```

Nur ausgewählte Services neu starten:

```bash
./setup.sh --only start,status --services uptime-kuma
./setup.sh --only start,status --services nginx
./setup.sh --only start,status --services nginx,uptime-kuma
```

## Service-Skripte für den Alltag

```bash
./scripts/services/start.sh uptime-kuma
./scripts/services/start.sh nginx uptime-kuma
./scripts/services/status.sh nginx uptime-kuma
./scripts/services/logs.sh uptime-kuma
./scripts/services/stop.sh uptime-kuma
./scripts/services/restart.sh nginx uptime-kuma
```

Für Rückwärtskompatibilität funktionieren auch die Wrapper unter `scripts/` weiter.

## Zugriff auf Services

### Monitoring

Empfohlen per vHost:

```text
http://monitoring.server
```

Damit `monitoring.server` auf die IP des Pi zeigt, brauchst du einen lokalen DNS- oder Hosts-Eintrag.

Beispiel:

```text
192.168.178.50 monitoring.server
```

### Postgres vom PC aus per SSH-Tunnel

Der Postgres-Port ist nur lokal auf dem Pi veröffentlicht:

```text
127.0.0.1:15432
```

Tunnel vom PC:

```bash
ssh -L 5432:127.0.0.1:15432 serveradmin@server
```

Danach in DBeaver oder pgAdmin:

- Host: `localhost`
- Port: `5432`
- User / Passwort / DB aus `.env`

## Wichtige Kurzbefehle

```bash
make setup
make preflight
make validate
make up
make down
make status
make logs
make restart-kuma
make restart-nginx
make restart-monitoring
```

## Backups

```bash
./scripts/backup/backup-postgres.sh
./scripts/backup/backup-data.sh
./scripts/backup/restore-postgres.sh /pfad/zur/datei.sql
```

## Dokumentation

- `docs/architecture.md`
- `docs/ports-and-networks.md`
- `docs/troubleshooting.md`
- `docs/restore-guide.md`
- `docs/refactoring/v1-plan.md`
