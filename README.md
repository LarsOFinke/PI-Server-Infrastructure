# Server Infrastructure Repo

Dieses Repo richtet die Basis-Infrastruktur auf dem Raspberry Pi ein und startet danach direkt die ersten Container.

## Enthalten

- Host-Bootstrap per `scripts/bootstrap-pi.sh`
- Nginx als Reverse Proxy
- Postgres als interne Datenbank
- Uptime Kuma als Monitoring
- Docker-Netzwerke für Frontend und Backend
- automatische Erstellung der `data/`-Ordner
- `monitoring.conf` bereits im Repo enthalten
- Preflight-Checks und `.env`-Validierung
- Setup-Logging und optionaler Debug-Modus
- Backup- und Restore-Skripte
- Dokumentation für Architektur, Ports und Troubleshooting

## Ablauf

### 1. Pi vorbereiten

- Raspberry Pi OS / Debian installieren
- SSH aktivieren
- Netzwerk prüfen

### 2. Git einmalig einrichten

```bash
sudo apt update
sudo apt install -y git
ssh-keygen -t ed25519 -C "deine-mail@example.com"
```

Public Key bei GitHub hinterlegen und Verbindung testen.

### 3. Repo klonen

```bash
git clone <DEIN-REPO-URL> ~/repositories/server
cd ~/repositories/server
chmod +x setup.sh scripts/*.sh
```

### 4. `.env` anpassen

Beim ersten Lauf wird `.env` automatisch aus `.env.example` erstellt.
Danach bitte mindestens `SERVER_USER` und `POSTGRES_PASSWORD` prüfen.

### 5. Komplettes Setup starten

```bash
./setup.sh
```

Mit Debug-Ausgabe:

```bash
DEBUG=true ./setup.sh
```


### Ablauf-Schnelldurchlauf

```sh
sudo apt update
sudo apt upgrade -y
sudo apt install -y git

git config --global user.name "..."
git config --global user.email "..."

ssh-keygen -t ed25519 -C "..."
ssh -T git@github.com

git clone <repo>
cd <repo>

chmod +x setup.sh scripts/*.sh
cp .env.example .env

./setup.sh
```


## Wichtige Kurzbefehle

```bash
make preflight
make validate
make up
make down
make status
make logs
```

## Backups

```bash
./scripts/backup-postgres.sh
./scripts/backup-data.sh
./scripts/restore-postgres.sh /pfad/zur/datei.sql
```

## Monitoring

Nach erfolgreichem Start erreichbar unter:

```text
http://<PI-IP>/monitoring/
```

## Dokumentation

- `docs/architecture.md`
- `docs/ports-and-networks.md`
- `docs/troubleshooting.md`
- `docs/restore-guide.md`
