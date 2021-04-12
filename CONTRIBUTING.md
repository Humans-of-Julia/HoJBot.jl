# Contribution Guide

If you have a new idea, we encourage you to discuss with other HoJBot developers
at the `#hoj-bots` channel on Discord. But, if you want to just work on it first
and surprise everyone later, that's also fine!

## Setting up Discord dev environment

As a Discord bot developer, you should create your own application/bot account
so that you can develop and test your code on your own. There are only a few
steps to get started:

1. [Create a new application](https://discord.com/developers/applications) using your Discord account.
    * See [Creating a Bot Account](https://discordpy.readthedocs.io/en/latest/discord.html#creating-a-bot-account) for specific info.
    * No need to make the bot public if only for testing purposes.
2. [Create a test Discord server](https://support.discord.com/hc/en-us/articles/204849977-How-do-I-create-a-server-) for your own local testing.
3. [Invite your bot](https://discord.com/developers/docs/topics/oauth2#bot-authorization-flow) to your own Discord server.
    * Follow the step 7 in [Creating a Bot Account](https://discordpy.readthedocs.io/en/latest/discord.html#creating-a-bot-account) to access the url to invite the bot to your test server.
    * Make sure that you use the right `client_id` and `permissions` values for generating the invite URL.

## Getting the HoJBot code

This project requires Julia 1.6. Please install that first if you haven't done so.

First, clone this repo.

```
git clone https://github.com/Humans-of-Julia/HoJBot.jl.git
```

Go inside the directory, and run this command to download dependencies.

```
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## Testing and making changes

At this point, you can start running the bot.

1. Locate your discord bot token from the Bot screen
2. Define `HOJBOT_DISCORD_TOKEN` environment variable in your shell profile.
3. Start the bot using `script/run.sh` script

Then, you can go to your own Discord server and enter some commands
to see if it's working properly. For example:

```
,j? sin
```

Now, you can change the source code and test. The easiest way is to make
a change, kill the program (hitting Ctrl-C, maybe several times), and
restart the bot.

## Learning from examples

Take a look at the code under `command` and `handler` folders for examples
about how to build stateless commands and watch message traffic and place
reactions on them.

Some features are stateful. Our current strategy is to keep things simple.
Rather than introducing a database to the system architecture, many problems
can be solved by simply saving/loading data in flat file formats such as
JSON. The `discourse` command provides a good example regarding serialization.

## Going through Pull Request reviews

Once you are happy with your HoJBot changes, you can go ahead and submit a PR.
All changes must be reviewed by a second person before merging to the `main`
branch.

We also have a HoJBot Test Server, where you can show off your bot enhancements
or ask fellow developers to help testing. Please contact `@tk3369#8593` or
`@CeterisParibus#5385` on Discord to get an invite link.
Typically, we want to run some tests on the test server before releasing new
functionality.

## Deploying to live site!

Once your code has been merged to the `main` branch and testing has been successful,
one of the bot admins will release it to the wild!
