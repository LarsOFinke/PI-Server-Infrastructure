# Refactoring v2 – Host Bootstrap entkoppeln

## Ziel

Das bisher große `bootstrap-pi.sh` wurde in kleine Host-Module zerlegt, damit die Host-Einrichtung leichter wartbar und testbarer wird.

## Neue Struktur

- `scripts/host/common.sh` – gemeinsame Host-Helfer
- `scripts/host/config.sh` – Feature-Flags für Host-Setup
- `scripts/host/lib/system.sh` – Updates und Basis-Pakete
- `scripts/host/lib/filesystem.sh` – tmpfs, Verzeichnisse, hushlogin
- `scripts/host/lib/security.sh` – SSH und UFW
- `scripts/host/lib/docker.sh` – Docker-Repo und Installation
- `scripts/host/lib/summary.sh` – Abschlussinformationen
- `scripts/host/bootstrap.sh` – schlanke Orchestrierung

## Nutzen

- geringere Komplexität pro Datei
- klarere Zuständigkeiten
- einfachere spätere Erweiterung, z. B. Fail2ban oder Tailscale
- besseres Debugging bei Host-Problemen
