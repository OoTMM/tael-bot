#!/bin/sh

set -e

# Install deps
pnpm install

# Start
exec "$@"
