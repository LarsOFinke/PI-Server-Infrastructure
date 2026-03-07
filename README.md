# Server Infrastructure Repo

Dieses Repo richtet die Basis-Infrastruktur auf dem Raspberry Pi ein und unterstützt zwei Modi:

- **vollständiges Setup** für einen frischen Pi
- **gezielte Teil-Läufe** für die Entwicklung, z. B. nur `nginx` oder nur `uptime-kuma`

## Enthalten

- Host-Bootstrap per `scripts/bootstrap-pi.sh`
- Nginx als Reverse Proxy
- Postgres als interne Datenbank
- Uptime Kuma als Monitoring
- Docker-Netzwerke für Frontend und Backend
- automatische Erstellung der `data/`-Ordner
- Preflight-Checks und `.env`-Validierung
- Setup-Logging und optionaler Debug-Modus
- Backup- und Restore-Skripte
- Dokumentation für Architektur, Ports und Troubleshooting

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
chmod +x setup.sh scripts/*.sh
```

### 4. `.env` anpassen

Beim ersten Lauf wird `.env` automatisch aus `.env.example` erstellt.
Danach bitte mindestens `SERVER_USER`, `POSTGRES_USER`, `POSTGRES_PASSWORD` und `POSTGRES_DB` prüfen.

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

## Teil-Läufe für Entwicklung und Debugging

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

## Direkt nutzbare Service-Skripte

Nur Kuma neu starten:

```bash
./scripts/start.sh uptime-kuma
```

Nginx und Kuma neu starten:

```bash
./scripts/start.sh nginx uptime-kuma
```

Status nur für bestimmte Services:

```bash
./scripts/status.sh nginx uptime-kuma
```

Logs nur für einen Service:

```bash
./scripts/logs.sh uptime-kuma
```

Einen Service stoppen:

```bash
./scripts/stop.sh uptime-kuma
```

## Zugriff auf Services

### Monitoring

Empfohlen per vHost:

```text
http://monitoring.local
```

Dafür muss `monitoring.local` auf die IP des Pi zeigen, z. B. über die lokale `hosts`-Datei.

Beispiel:

```text
192.168.178.50 monitoring.local
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
./scripts/backup-postgres.sh
./scripts/backup-data.sh
./scripts/restore-postgres.sh /pfad/zur/datei.sql
```

## Dokumentation

- `docs/architecture.md`
- `docs/ports-and-networks.md`
- `docs/troubleshooting.md`
- `docs/restore-guide.md`
