#!/bin/bash
# Start the HoJBot program

if [[ -z "$HOJBOT_DISCORD_TOKEN" ]]; then
    echo "Error: please set up HOJBOT_DISCORD_TOKEN environment variable"
    exit 1
fi

# Default environment settings
: ${TZ=UTC}
: ${RUN_ONCE=no}
: ${RUN_DURATION_MINUTES=2880}
: ${RESTART_THROTTLE_SECONDS=10}

while true; do
    echo "`date`: Starting HoJBot..."
    julia --project=. -e "using Pkg; Pkg.instantiate(); using HoJBot, Dates; start_bot(; run_duration = Minute(${RUN_DURATION_MINUTES}));"
    if [[ "$RUN_ONCE" == "yes" ]]; then
        break
    fi
    echo "`date`: throttling for $RESTART_THROTTLE_SECONDS seconds before restart."
    echo "`date`: you may hit Ctrl-C to shut down completely."
    sleep $RESTART_THROTTLE_SECONDS
done
echo "`date`: Program exited normally"
