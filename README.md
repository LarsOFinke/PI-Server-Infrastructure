# Server Infrastructure Repo

Minimalistisches Infrastruktur-Repo für deinen Raspberry Pi.

## Ziel

Der Host bleibt schlank und stellt nur die Basis bereit:

- Docker
- Docker Compose Plugin
- Firewall
- SSH-Härtung
- ein paar Diagnose-Tools

Die eigentlichen Dienste laufen in Docker:

- Nginx als Reverse Proxy
- Postgres als Datenbank
- Uptime Kuma als Monitoring

## Empfohlener Ablauf

### 1. Pi frisch installieren

Zum Beispiel Raspberry Pi OS / Debian, Benutzer anlegen, SSH aktivieren, Netzwerk prüfen.

### 2. Git und GitHub-SSH einmalig manuell einrichten

Beispiel:

```bash
sudo apt update
sudo apt install -y git
git config --global user.name "Vorname Nachname"
git config --global user.email "deine.email@web.de"
ssh-keygen -t ed25519 -C "deine.email@web.de"
cat ~/.ssh/id_ed25519.pub
ssh -T git@github.com
```

Dann das Repo klonen.

### 3. Setup aus dem Repo starten

```bash
chmod +x setup.sh scripts/*.sh
./setup.sh
```

### 4. Falls nötig neu anmelden

Wenn dein Benutzer neu zur `docker`-Gruppe hinzugefügt wurde, bitte einmal neu anmelden oder den Pi rebooten.

### 5. Infrastruktur starten

```bash
./scripts/start.sh
./scripts/status.sh
```

## Repo-Struktur

```text
server/
├── setup.sh
├── compose.yml
├── .env.example
├── README.md
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
│       ├── monitoring.conf
│       └── placeholders.conf
├── db/
│   └── init/
│       └── 01-init.sql
├── data/
│   ├── postgres/
│   ├── nginx/
│   └── uptime-kuma/
├── logs/
└── scripts/
    ├── bootstrap-pi.sh
    ├── init-env.sh
    ├── post-setup-check.sh
    ├── start.sh
    ├── status.sh
    └── stop.sh
```

## Was `setup.sh` macht

1. `bootstrap-pi.sh` bereitet den Host vor.
2. `init-env.sh` erstellt bei Bedarf eine `.env` aus `.env.example`.
3. `post-setup-check.sh` prüft Docker, Compose und die wichtigsten Voraussetzungen.

## Was `bootstrap-pi.sh` absichtlich **nicht** macht

- kein GitHub-SSH-Key-Setup
- kein persönliches Git-User-Setup
- keine Projekt-Repositories klonen

Das bleibt bewusst ein manueller, einmaliger Schritt.

## Erreichbarkeit nach dem Start

- Monitoring: `http://<PI-IP>/monitoring/`
- Postgres: nur intern im Docker-Backend-Netzwerk

## Nächste Schritte

Wenn die Infrastruktur läuft, können danach Projekt-Container ergänzt werden, zum Beispiel:

- todo-app
- project-manager
- finance-manager

Diese werden dann per zusätzlicher Nginx-Konfiguration an den Reverse Proxy gehängt.
