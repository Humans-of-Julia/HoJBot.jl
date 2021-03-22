# HoJBot

This is the Discord bot for Humans of Julia community server.

## Features

1. The "happy reactor": automatically react to your message with smiley when a message sounds happy.

2. Time zone command (`tz`): easily convert a date/time into multiple predefined timezones.

## Contributions

All HoJ members are invited to contribute to this project.
Here's how to get started.

One-time setup for your dev environment:
1. [Create a new application](https://discord.com/developers/applications) using your Discord account
2. [Create a test Discord server](https://support.discord.com/hc/en-us/articles/204849977-How-do-I-create-a-server-) for your own local testing
3. [Invite your bot](https://discord.com/developers/docs/topics/oauth2#bot-authorization-flow) to your own Discord server. Make sure that you use the right `client_id` and `permissions` values in the URL.

Testing with your own server:
1. Locate your discord bot token from the Bot screen
2. Define `HOJBOT_DISCORD_TOKEN` environment variable in your shell profile.
3. Start the bot using `script/run.sh` script

Take a look at the code under `command` and `handler` folders for examples
about how to build stateless commands and watch message traffic and place
reactions on them.
