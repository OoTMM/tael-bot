#!/bin/sh

set -e

# Migrate
npm run migrate up

# Start
exec npm start
