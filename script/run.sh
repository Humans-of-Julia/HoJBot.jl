#!/bin/bash

if [[ -z "$HOJBOT_DISCORD_TOKEN" ]]; then
    echo "Error: please set up HOJBOT_DISCORD_TOKEN environment variable"
    exit 1
fi

julia --project=. -e 'using HoJBot; start_bot();'
