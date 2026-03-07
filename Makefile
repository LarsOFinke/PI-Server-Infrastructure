SHELL := /usr/bin/env bash

.PHONY: setup preflight validate up down status logs backup-postgres backup-data restore-postgres

setup:
	./setup.sh

preflight:
	./scripts/preflight-check.sh

validate:
	./scripts/validate.sh

up:
	./scripts/start.sh

down:
	./scripts/stop.sh

status:
	./scripts/status.sh

logs:
	./scripts/logs.sh

backup-postgres:
	./scripts/backup-postgres.sh

backup-data:
	./scripts/backup-data.sh

restore-postgres:
	./scripts/restore-postgres.sh
