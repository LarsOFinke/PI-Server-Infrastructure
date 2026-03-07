#!/usr/bin/env bash
set -Eeuo pipefail

########################################

# Server Infrastructure Setup Script

########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "================================="
echo "Server Infrastructure Setup"
echo "================================="

########################################

# ENV FILE LADEN

########################################

if [ -f ".env" ]; then
echo "Loading .env configuration..."
source .env
else
echo "ERROR: .env file not found."
echo "Please create it from .env.example"
exit 1
fi

########################################

# USER ERMITTELN

########################################

USERNAME="${SERVER_USER:-${SUDO_USER:-${USER:-pi}}}"

echo "Using user: $USERNAME"

########################################

# BOOTSTRAP HOST

########################################

echo
echo "Running host bootstrap..."
bash scripts/bootstrap-pi.sh

########################################

# DATA DIRECTORIES

########################################

echo
echo "Creating data directories..."

mkdir -p data/postgres
mkdir -p data/nginx
mkdir -p data/monitoring

chmod -R 750 data

echo "Data directories ready."

########################################

# DOCKER CHECK

########################################

echo
echo "Checking Docker..."

if ! command -v docker &> /dev/null; then
echo "ERROR: Docker not installed."
exit 1
fi

echo "Docker version:"
docker --version

if ! docker compose version &> /dev/null; then
echo "ERROR: Docker Compose plugin missing."
exit 1
fi

########################################

# OPTIONAL: START INFRASTRUCTURE

########################################

echo
read -p "Start infrastructure containers now? (y/N): " START_CONTAINERS

if [[ "$START_CONTAINERS" =~ ^[Yy]$ ]]; then
echo "Starting containers..."
docker compose up -d
else
echo "Skipping container startup."
fi

########################################

# STATUS INFO

########################################

echo
echo "================================="
echo "Setup finished"
echo "================================="

echo "Next steps:"
echo "1) logout/login if docker group was added"
echo "2) start infrastructure:"
echo "   docker compose up -d"
echo "3) check status:"
echo "   docker compose ps"
