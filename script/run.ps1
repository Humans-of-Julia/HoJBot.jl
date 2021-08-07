#! /usr/bin/pwsh
if($env:HOJBOT_DISCORD_TOKEN -eq $null){
    Write-Host "Error: please set up HOJBOT_DISCORD_TOKEN environment variable"
    exit 1
}
else {
    # Write-Host "$env:HOJBOT_DISCORD_TOKEN"
    $env:TZ="utc"
    $env:RUN_ONCE="no"
    $env:RUN_DURATION_MINUTES=2880
    $env:RESTART_THROTTLE_SECONDS=10

    while($true){
        Write-Host "$(Get-Date): Starting HoJBot..."
        julia --project=. -e "using Pkg; Pkg.instantiate(); using HoJBot, Dates; start_bot(; run_duration = Minute($env:RUN_DURATION_MINUTES));"
        if($env:RUN_ONCE -eq "no"){
            break
        }
        Write-Host "$(Get-Date): throttling for $env:RESTART_THROTTLE_SECONDS seconds before restart."
        Start-Sleep $env:RESTART_THROTTLE_SECONDS
    }
    Write-Host "$(Get-Date): Program exited normally"
}