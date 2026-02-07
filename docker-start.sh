#!/bin/bash

# Run migrations
bin/tael_bot eval 'TaelBot.Release.migrate' || exit 1

# Start the server
exec bin/tael_bot start
