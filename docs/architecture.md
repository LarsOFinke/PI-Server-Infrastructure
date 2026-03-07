# Architektur

## Host

Der Raspberry Pi Host übernimmt nur die Basisaufgaben:

- SSH
- UFW
- Docker Engine
- Diagnose-Tools wie `tcpdump`

## Container

Die eigentliche Infrastruktur läuft in Docker:

- `nginx` als Reverse Proxy
- `postgres` als interne Datenbank
- `uptime-kuma` als Monitoring

## Netzwerke

- `frontend`: für veröffentlichte Web-Zugriffe über Nginx
- `backend`: für interne Container-Kommunikation
