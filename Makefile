SHELL := /usr/bin/env bash

.PHONY: setup setup-core setup-monitoring up down status logs restart-kuma restart-nginx restart-monitoring backup-postgres backup-data restore-postgres

setup:
	./setup.sh

setup-core:
	./setup.sh --profile core --non-interactive

setup-monitoring:
	./setup.sh --features monitoring,checks --non-interactive

up:
	./scripts/services/start.sh

down:
	./scripts/services/stop.sh

status:
	./scripts/services/status.sh

logs:
	./scripts/services/logs.sh

restart-kuma:
	./scripts/services/restart.sh uptime-kuma

restart-nginx:
	./scripts/services/restart.sh nginx

restart-monitoring:
	./scripts/services/restart.sh nginx uptime-kuma

backup-postgres:
	./scripts/backup/backup-postgres.sh

backup-data:
	./scripts/backup/backup-data.sh

restore-postgres:
	./scripts/backup/restore-postgres.sh
