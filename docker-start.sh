#!/bin/sh

set -e

# Migrate
pnpm migrate up

# Start
exec "$@"
