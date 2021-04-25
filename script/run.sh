#!/bin/bash
# Start the HoJBot program

if [[ -z "$HOJBOT_DISCORD_TOKEN" ]]; then
    echo "Error: please set up HOJBOT_DISCORD_TOKEN environment variable"
    exit 1
fi

if [[ -z "$FINNHUB_TOKEN" ]]; then
    echo "Warning: FINNHUB_TOKEN must be set for investment game to function properly."
    echo "  Get your own token at https://finnhub.io/"
fi

# Default environment settings
: ${RUN_ONCE=no}
: ${RUN_DURATION_MINUTES=2880}

while true; do
    echo "`date`: Starting HoJBot..."
    julia --project=. -e "using HoJBot, Dates; start_bot(; run_duration = Minute(${RUN_DURATION_MINUTES}));"
    if [[ "$RUN_ONCE" == "yes" ]]; then
        break
    fi
    THROTTLE=10
    echo "`date`: throttling for $THROTTLE seconds before restart."
    echo "`date`: you may hit Ctrl-C to shut down completely."
    sleep $THROTTLE
done
echo "`date`: Program exited normally"
