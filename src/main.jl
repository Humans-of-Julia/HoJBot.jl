const active_commands = LittleDict([
    :gm => false,
    :help => true,
    :j => true,
    :react => true,
    :tz => true,
])

const commands_names = LittleDict([
    :gm => :game_master,
    :help => :global_help,
    :j => :julia_doc,
    :react => :reaction,
    :tz => :time_zone
])

const handlers_list = LittleDict([
    :reaction => true,
])

const opt_services_list = Set([
    :game_master,
    :reaction,
])

function start_bot()
    global client = Client(ENV["HOJBOT_DISCORD_TOKEN"];
        presence = (game = (name = "HoJ", type = AT_GAME),),
        prefix = COMMAND_PREFIX)
    init_handlers!(client)
    init_commands!(client)
    open(client)
    wait(client)
end

function init_handlers!(client::Client)
    for handler in handlers_list
        handlers_list[handler] && add_handler!(client, MessageCreate, handler)
    end
end

function init_commands!(client::Client)
    for command in active_commands
        if active_commands(command)
        add_command!(client, command, (c, m) -> commander(c, m, commands_names[command]))
        end
    end
end

commander(c::Client, m::Message, service) = commander(c, m, Val(service))
help_commander(c::Client, m::Message, service) = help_commander(c, m, Val(service))

function get_opt(username, discriminator)
    user = username * "_" * discriminator
    path = joinpath(pwd(), "data", "opt", user)
    !isfile(path) && write(path, "{}")
    return JSON.parsefile(path; dicttype = LittleDict)
end

function get_opt!(username, discriminator, service)
    return get!(get_opt(username, discriminator), string(service), false)
end

function set_opt!(username, discriminator, service, value)
    opt = get_opt(username, discriminator)
    opt[string(service)] = value
    user = username * "_" * discriminator
    path = joinpath(pwd(), "data", "opt", user)
    write(path, json(opt))
end

function opt_in(c::Client, m::Message, service)
    username = m.author.username
    discriminator = m.author.discriminator
    if service ∉ opt_services_list
        reply(c, m,
            """
            Oh, @$username#$discriminator, the `$(string(service))` service either does not exist or accept opt-in/opt-out requests!
            """
        )
    elseif get_opt!(username, discriminator, service)
        reply(c, m,
            """
            Oh, @$username#$discriminator, you already suscribed to the `$(string(service))` service!
            """
        )
    else
        set_opt!(username, discriminator, service, true)
        reply(c, m,
            """
            Thanks @$username#$discriminator for joining our `$(string(service))` service!
            """
        )
    end
end

function opt_out(c::Client, m::Message, service)
    username = m.author.username
    discriminator = m.author.discriminator
    if service ∉ opt_services_list
        reply(c, m,
            """
            Oh, @$username#$discriminator, the `$(string(service))` service either does not exist or accept opt-in/opt-out requests!
            """
        )
    elseif !get_opt!(username, discriminator, service)
        reply(c, m,
            """
            Oh, @$username#$discriminator, you haven't suscribed to the `$(string(service))` service!
            """
        )
    else
        set_opt!(username, discriminator, service, false)
        reply(c, m,
            """
            It is sad that you're leaving our `$(string(service))` service, @$username#$discriminator. We hope you will come back soon and enjoy other HoJBot stuff!
            """
        )
    end
end
