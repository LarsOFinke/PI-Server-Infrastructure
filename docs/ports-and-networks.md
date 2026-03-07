# Ports und Netzwerke

## Extern veröffentlichte Ports

- `80/tcp` über Nginx
- `443/tcp` ist im UFW-Setup vorbereitet, aktuell aber noch nicht im Compose veröffentlicht

## Interne Container-Ports

- `postgres:5432`
- `uptime-kuma:3001`

## Grundregel

Nur Nginx bekommt veröffentlichte Ports. Datenbank und Monitoring bleiben intern und werden über das Backend-Netzwerk erreicht.
