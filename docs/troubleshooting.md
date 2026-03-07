# Troubleshooting

## Setup bricht beim Docker-Start mit "permission denied" ab

Die docker-Gruppenzuweisung ist in der aktuellen Session noch nicht aktiv.

Lösung:

```bash
logout
# oder neue SSH-Session öffnen
./setup.sh
```

Alternativ:

```bash
newgrp docker
./setup.sh
```

## Nur einen Service neu starten

```bash
./scripts/start.sh uptime-kuma
./scripts/start.sh nginx
./scripts/start.sh nginx uptime-kuma
```

## Status und Logs prüfen

```bash
./scripts/status.sh
./scripts/status.sh uptime-kuma
./scripts/logs.sh nginx
./scripts/logs.sh uptime-kuma
```

## Nginx-Konfiguration testen und neu laden

```bash
docker compose exec nginx nginx -t
docker compose exec nginx nginx -s reload
```

## Uptime Kuma über vHost statt Unterpfad

Das Repo ist für `monitoring.local` vorbereitet. Wenn der Name nicht funktioniert, muss dein PC ihn lokal auf die Pi-IP auflösen.

Beispiel hosts-Datei:

```text
192.168.178.50 monitoring.local
```

## Postgres sicher vom PC aus erreichen

```bash
ssh -L 5432:127.0.0.1:15432 serveradmin@server
```
