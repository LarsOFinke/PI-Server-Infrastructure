# PI Server Infrastructure

Dieses Repo richtet die Basis-Infrastruktur auf einem Raspberry Pi oder Debian-Host ein und hält das Setup bewusst modular.

## Refactoring-Stand

Das Repo wurde bis **Refactoring v4** konsolidiert. Gemeinsame Prüf- und Hilfslogik liegt nun zentral in `scripts/common/`, während Setup-, Service- und Backup-Skripte bewusst dünn gehalten sind.

## Zielbild

Die Infrastruktur besteht aus:

- `nginx` als Reverse Proxy
- `postgres` als interne Datenbank
- `uptime-kuma` als Monitoring
- Host-Bootstrap für Docker, Firewall, SSH-Härtung und Standardverzeichnisse
- Backup- und Restore-Skripten

## Repo-Struktur

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
    ├── host/
    ├── setup/
    ├── services/
    └── backup/
```

## Feature-basierter Setup-Ablauf

`setup.sh` fragt standardmäßig am Anfang ab, welche Features eingerichtet werden sollen.

Verfügbare Features:

- `host` – Host vorbereiten
- `nginx` – Nginx-Container bereitstellen
- `postgres` – Postgres-Container bereitstellen
- `monitoring` – Uptime Kuma bereitstellen
- `backup` – Backup-Verzeichnisse vorbereiten
- `checks` – Validierungen und Post-Setup-Checks ausführen

Standardmäßig sind in der interaktiven Auswahl aktiv:

- `host`
- `nginx`
- `postgres`
- `monitoring`
- `checks`

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
chmod +x setup.sh
find scripts -type f -name "*.sh" -exec chmod +x {} +
```

### 4. Setup starten

```bash
./setup.sh
```

Beim ersten Lauf wird `.env` automatisch aus `.env.example` erstellt.
Pflichtvariablen stehen in `config/env/required.env.keys`.

## Nicht-interaktive Nutzung

Bestimmte Features direkt auswählen:

```bash
./setup.sh --features host,nginx,postgres,monitoring,checks
./setup.sh --features monitoring
./setup.sh --features nginx,monitoring --no-start
```

Profile verwenden:

```bash
./setup.sh --profile core
./setup.sh --profile full
./setup.sh --profile monitoring-only
./setup.sh --profile services --non-interactive
```

Verfügbare Profile:

- `core` / `minimal`
- `full`
- `host-only`
- `services`
- `monitoring-only`

## Container und Services im Alltag

Services gezielt starten oder aktualisieren:

```bash
./scripts/services/start.sh uptime-kuma
./scripts/services/start.sh nginx uptime-kuma
./scripts/services/status.sh nginx uptime-kuma
./scripts/services/logs.sh uptime-kuma
./scripts/services/stop.sh uptime-kuma
./scripts/services/restart.sh nginx uptime-kuma
```

## Zugriff auf Services

### Monitoring

```text
http://monitoring.server
```

Damit `monitoring.server` auf die IP des Pi zeigt, brauchst du einen lokalen DNS- oder Hosts-Eintrag.

Beispiel:

```text
192.168.178.50 monitoring.server
```

### Postgres vom PC aus per SSH-Tunnel

Postgres ist nur lokal auf dem Pi veröffentlicht:

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

## Makefile-Kurzbefehle

```bash
make setup
make setup-core
make setup-monitoring
make preflight
make validate
make up
make down
make status
make logs
make restart-kuma
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
- `docs/refactoring/v2-plan.md`
- `docs/refactoring/v3-plan.md`
