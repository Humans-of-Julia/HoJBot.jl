# Contribution Guide

## Setting up Discord dev environment

1. [Create a new application](https://discord.com/developers/applications) using your Discord account.
    * See [Creating a Bot Account](https://discordpy.readthedocs.io/en/latest/discord.html#creating-a-bot-account) for specific info.
    * No need to make the bot public if only for testing purposes.
2. [Create a test Discord server](https://support.discord.com/hc/en-us/articles/204849977-How-do-I-create-a-server-) for your own local testing.
3. [Invite your bot](https://discord.com/developers/docs/topics/oauth2#bot-authorization-flow) to your own Discord server.
    * Follow the step 7 in [Creating a Bot Account](https://discordpy.readthedocs.io/en/latest/discord.html#creating-a-bot-account) to access the url to invite the bot to your test server.
    * Make sure that you use the right `client_id` and `permissions` values for generating the invite URL.

## Get the HoJBot code

1. Clone this repo
2. Start a julia REPL in the directory with `julia --project=.`
3. Instantiate the project to download dependencies with `] instantiate`
4. Exit julia REPL

## Testing your code

1. Locate your discord bot token from the Bot screen
2. Define `HOJBOT_DISCORD_TOKEN` environment variable in your shell profile.
3. Start the bot using `script/run.sh` script

## Learn from examples

Take a look at the code under `command` and `handler` folders for examples
about how to build stateless commands and watch message traffic and place
reactions on them.
