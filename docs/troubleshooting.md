# Troubleshooting

## Setup mit Debug-Modus ausführen

```bash
DEBUG=true ./setup.sh
```

## Aktuellen Status prüfen

```bash
./scripts/status.sh
```

## Container-Logs ansehen

```bash
./scripts/logs.sh
./scripts/logs.sh nginx
./scripts/logs.sh postgres
```

## Compose-Konfiguration validieren

```bash
./scripts/validate.sh
```

## Typische Ursachen

### Docker-Rechte greifen noch nicht

Nach `usermod -aG docker <user>` bitte neu anmelden oder rebooten.

### Port 80 ist belegt

```bash
ss -tulpn | grep ':80'
```

### Monitoring ist nicht erreichbar

- `docker compose ps` prüfen
- `./scripts/logs.sh nginx` prüfen
- `./scripts/logs.sh uptime-kuma` prüfen
