#!/bin/sh

set -e

# Install deps
npm install
npm install -g tsx

# Start
exec "$@"
