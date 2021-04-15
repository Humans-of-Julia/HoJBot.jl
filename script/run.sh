#!/bin/bash
# Start the HoJBot program

if [[ -z "$HOJBOT_DISCORD_TOKEN" ]]; then
    echo "Error: please set up HOJBOT_DISCORD_TOKEN environment variable"
    exit 1
fi

# Default environment settings
: ${RUN_ONCE=no}
: ${RUN_DURATION_MINUTES=360}

while true; do
    echo "`date`: Starting HoJBot..."
    julia --project=. -e "using HoJBot, Dates; start_bot(; run_duration = Minute(${RUN_DURATION_MINUTES}));"
    if [[ "$RUN_ONCE" == "yes" ]]; then
        break
    fi
    sleep 1  # throttle to avoid a hot loop when the process keep crashing
done
echo "`date`: Program exited normally"
