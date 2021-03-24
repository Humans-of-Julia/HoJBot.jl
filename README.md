# HoJBot

This is the Discord bot for Humans of Julia community server.

## Features

1. The _happy reactor_: automatically reacts to your message with a smiley when your message sounds happy. Similarly, there are also _excited_ and _disappointed_ reactors.

2. The time zone command (`tz`): easily convert a date/time into multiple predefined timezones. This is perfect for setting up meeting time that works for our global community.

Quick demo:

![demo](images/demo.gif)

## Contributions

All HoJ members are invited to contribute to this project.
Here's how to get started.

Set up Discord dev environment:
1. [Create a new application](https://discord.com/developers/applications) using your Discord account
2. [Create a test Discord server](https://support.discord.com/hc/en-us/articles/204849977-How-do-I-create-a-server-) for your own local testing
3. [Invite your bot](https://discord.com/developers/docs/topics/oauth2#bot-authorization-flow) to your own Discord server. Make sure that you use the right `client_id` and `permissions` values in the URL.

Get the HoJBot code:
1. Clone this repo
2. Start a julia REPL in the directory with `julia --project=.`
3. Instantiate the project to download dependencies with `] instantiate`
4. Exit julia REPL

Testing:
1. Locate your discord bot token from the Bot screen
2. Define `HOJBOT_DISCORD_TOKEN` environment variable in your shell profile.
3. Start the bot using `script/run.sh` script

Take a look at the code under `command` and `handler` folders for examples
about how to build stateless commands and watch message traffic and place
reactions on them.
