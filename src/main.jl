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
    add_command!(client, :gm, game_master_commander)
end

# Purely informative atm
const opt_services_list = Set([
    :game_master,
    :reaction,
])

commander(c::Client, m::Message, service) = commander(c, m, Val(service))
help_commander(c::Client, m::Message, service) = help_commander(c, m, Val(service))

function get_opt(username, discriminator)
    user = username * "_" * discriminator
    path = joinpath(pwd(), "data", "opt", user)
    !isfile(path) && write(path, "{}")
    return JSON.parsefile(path; dicttype = LittleDict)
end

function get_opt!(username, discriminator, service)
    return get!(get_opt(username, discriminator), service, false)
end

function set_opt!(username, discriminator, service, value)
    opt = get_opt(username, discriminator)
    opt[service] = value
    user = username * "_" * discriminator
    path = joinpath(pwd(), "data", "opt", user)
    write(path, json(opt))
end

function opt_in(c::Client, m::Message, service)
    username = m.author.username
    discriminator = m.author.discriminator
    if get_opt!(username, discriminator, service)
        reply(c, m,
        """
        Oh, @$username#$discriminator, you already suscribed to the $service service!
        """
    )
    else
        set_opt!(username, discriminator, service, true)
        reply(c, m,
        """
        Thanks @$username#$discriminator for joining our $service service!
        """
    )
    end
end

function opt_out(c::Client, m::Message, service)
    username = m.author.username
    discriminator = m.author.discriminator
    if get_opt!(username, discriminator, service)
        reply(c, m,
            """
            Oh, @$username#$discriminator, you haven't suscribed to the $service service!
            """
        )
    else
        set_opt!(username, discriminator, service, false)
        reply(c, m,
            """
            It is sad that you're leaving our $service service, @$username#$discriminator. We hope you will come back soon and enjoy other HoJBot stuff!
            """
        )
    end
end
