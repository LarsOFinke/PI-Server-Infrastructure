# Troubleshooting

## Docker-Zugriff nach dem ersten Setup fehlt

Wenn `docker compose` mit `permission denied` auf `/var/run/docker.sock` fehlschlägt, wurde der Benutzer meist gerade erst zur `docker`-Gruppe hinzugefügt.

Lösung:

1. neu anmelden oder rebooten
2. danach `./setup.sh` oder `./scripts/services/start.sh` erneut ausführen

## monitoring.server funktioniert nicht

Das Repo ist für `monitoring.server` vorbereitet. Wenn der Name nicht funktioniert, muss dein PC ihn lokal auf die Pi-IP auflösen.

Beispiel Hosts-Eintrag:

```text
192.168.178.50 monitoring.server
```

## Nginx-Config prüfen

```bash
docker compose exec nginx nginx -t
docker compose exec nginx nginx -T
```

## Nur einzelne Services neu starten

```bash
./scripts/services/restart.sh uptime-kuma
./scripts/services/restart.sh nginx uptime-kuma
```

## Nur Monitoring neu einrichten

```bash
./setup.sh --features monitoring,checks --non-interactive
```
