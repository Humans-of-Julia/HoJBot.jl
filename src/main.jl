const active_commands = LittleDict([
    :gm => false,
    :j => true,
    :react => true,
    :tz => true,
    :discourse => true,
])

const commands_names = LittleDict([
    :gm => :game_master,
    :j => :julia_doc,
    :react => :reaction,
    :tz => :time_zone,
    :discourse => :discourse,
])

const handlers_list = [
    (:reaction, MessageCreate, true),
    (:whistle, MessageReactionAdd, true),
    (:discourse, MessageReactionAdd, true),
]

const opt_services_list = [
    :game_master,
    :reaction,
]

function help_message()
    act_commands = collect(keys(filter(c -> c.second, active_commands)))
    names = collect(values(filter(c -> active_commands[c.first], commands_names)))

    commands = mapreduce(c -> string(c) * "\n", *, act_commands)
    opt = mapreduce(c -> string(c) * "\n", *, filter(c -> c ∈ names, opt_services_list))
    str = """
    ```
    HoJBot accepts the following commands:
    ```
    $commands
    ```
    The following services are opt-in. Please check the related help command (`service help` for any `service` below).
    ```
    $opt
    """
    return str
end

function start_bot(;
    commands = active_commands,
    handlers = handlers_list,
)
    @info "Starting bot... command prefix = $COMMAND_PREFIX"
    global client = Client(ENV["HOJBOT_DISCORD_TOKEN"];
        presence = (game = (name = "HoJ", type = AT_GAME),),
        prefix = COMMAND_PREFIX)
    init_handlers!(client, handlers)
    init_commands!(client, commands)
    # add_help!(client; help = help_message())
    open(client)
    wait(client)
end

function init_handlers!(client::Client, handlers)
    for (symbol, event, active) in handlers
        active && add_handler!(client, event, (c, e) -> handler(c, e, Val(symbol)))
    end
end

function init_commands!(client::Client, commands)
    for (com, active) in commands
        active && add_command!(client, com, (c, m) -> commander(c, m, commands_names[com]))
    end
end

commander(c::Client, m::Message, service) =
begin
    @info "commander" c m service
    commander(c, m, Val(service))
end
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
