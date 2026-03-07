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

Das Script erledigt:

1. `.env` erzeugen und laden
2. Host bootstrapen
3. `data/nginx`, `data/postgres` und `data/uptime-kuma` erstellen
4. Konfiguration prüfen
5. Container starten
6. Status anzeigen

## Aufruf danach

```bash
./scripts/status.sh
./scripts/stop.sh
./scripts/start.sh
```

## Monitoring

Nach erfolgreichem Start erreichbar unter:

```text
http://<PI-IP>/monitoring/
```
