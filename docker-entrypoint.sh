#!/bin/sh

set -e

# Install deps
npm install

exec "$@"
