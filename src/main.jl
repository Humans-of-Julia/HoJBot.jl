function start_bot()
    global client = Client(ENV["HOJBOT_DISCORD_TOKEN"];
        presence = (game = (name = "HoJ", type = AT_GAME),),
        prefix = COMMAND_PREFIX)
    # init_handlers!(client)
    init_commands!(client)
    open(client)
    wait(client)
end

function init_handlers!(client::Client)
    add_handler!(client, MessageCreate, react_handler)
end

function init_commands!(client::Client)
    add_command!(client, :tz, time_zone_commander)
    add_command!(client, :j, julia_commander)
end
