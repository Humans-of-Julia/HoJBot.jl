function help_message()
    act_commands = collect(keys(filter(c -> c.second, ACTIVE_COMMANDS)))
    names = collect(values(filter(c -> ACTIVE_COMMANDS[c.first], COMMANDS_NAMES)))

    commands = mapreduce(c -> string(c) * "\n", *, act_commands)
    opt = mapreduce(c -> string(c) * "\n", *, filter(c -> c ∈ names, OPT_SERVICES_LIST))
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
    commands=ACTIVE_COMMANDS,
    handlers=HANDLERS_LIST,
    run_duration=Minute(365 * 24 * 60),  # run for a very long time by default
)
    @info "Starting bot... command prefix = $COMMAND_PREFIX"
    global client = Client(
        ENV["HOJBOT_DISCORD_TOKEN"];
        presence=(game = (name = "HoJ", type = AT_GAME),),
        prefix=COMMAND_PREFIX,
    )
    init_handlers!(client, handlers)
    init_commands!(client, commands)
    # add_help!(client; help = help_message())
    warm_up_enabled() && warm_up()
    open(client)
    auto_shutdown(client, run_duration, "SHUTDOWN")
    wait(client)
end

function init_handlers!(client::Client, handlers)
    for (symbol, event, active) in handlers
        active && add_handler!(client, event, (c, e) -> handler(c, e, Val(symbol)))
    end
end

function init_commands!(client::Client, commands)
    for (com, active) in commands
        active && add_command!(client, com, (c, m) -> commander(c, m, COMMANDS_NAMES[com]))
    end
end

"""
    auto_shutdown(run_duration::TimePeriod)

Run a background process to track the program's run time and exit
the program when it has exceeded the specified `run_duration` or
when a file exists at `trigger_path`.
"""
function auto_shutdown(c::Client, run_duration::TimePeriod, trigger_path::AbstractString="")
    start_time = now()
    @async while true
        if now() > start_time + run_duration
            @info "Times up! The bot is shutting down automatically."
            shutdown_gracefully(c)
            break
        end
        if length(trigger_path) > 0 && isfile(trigger_path)
            @info "The bot is shutting down via trigger path `$trigger_path`."
            rm(trigger_path)
            shutdown_gracefully(c)
            break
        end
        sleep(5)
    end
end

function shutdown_gracefully(c::Client)
    try
        close(c)
    catch ex
        @warn "Unable to close client connection" ex
    end
end

function commander(c::Client, m::Message, service::Symbol)
    @info "commander requested" c m service
    commander(c, m, Val(service))
end
help_commander(c::Client, m::Message, service::Symbol) = help_commander(c, m, Val(service))

function get_opt(username, discriminator)
    user = username * "_" * discriminator
    path = joinpath(pwd(), "data", "opt", user)
    !isfile(path) && write(ensurepath!(path), "{}")
    return JSON.parsefile(path; dicttype=LittleDict)
end

function get_opt!(username, discriminator, service)
    get!(get_opt(username, discriminator), string(service), false)
end

function set_opt!(username, discriminator, service, value)
    opt = get_opt(username, discriminator)
    opt[string(service)] = value
    user = username * "_" * discriminator
    path = joinpath(pwd(), "data", "opt", user)
    write(ensurepath!(path), json(opt))
end

function opt_in(c::Client, m::Message, service)
    username = m.author.username
    discriminator = m.author.discriminator
    if service ∉ OPT_SERVICES_LIST
        reply(
            c,
            m,
            """
            Oh, @$username#$discriminator, the `$(string(service))` service either does not exist or accept opt-in/opt-out requests!
            """,
        )
    elseif get_opt!(username, discriminator, service)
        reply(
            c,
            m,
            """
            Oh, @$username#$discriminator, you already suscribed to the `$(string(service))` service!
            """,
        )
    else
        set_opt!(username, discriminator, service, true)
        reply(
            c,
            m,
            """
            Thanks @$username#$discriminator for joining our `$(string(service))` service!
            """,
        )
    end
end

function opt_out(c::Client, m::Message, service)
    username = m.author.username
    discriminator = m.author.discriminator
    if service ∉ OPT_SERVICES_LIST
        reply(
            c,
            m,
            """
            Oh, @$username#$discriminator, the `$(string(service))` service either does not exist or accept opt-in/opt-out requests!
            """,
        )
    elseif !get_opt!(username, discriminator, service)
        reply(
            c,
            m,
            """
            Oh, @$username#$discriminator, you haven't suscribed to the `$(string(service))` service!
            """,
        )
    else
        set_opt!(username, discriminator, service, false)
        reply(
            c,
            m,
            """
            It is sad that you're leaving our `$(string(service))` service, @$username#$discriminator. We hope you will come back soon and enjoy other HoJBot stuff!
            """,
        )
    end
end

function warm_up_enabled()
    return get(ENV, "ENABLE_WARM_UP", "1") in ("1", "Y", "YES")
end

# TODO use SnoopCompile to find precompile methods
function warm_up()
    @info "Warming up..."
    Threads.@spawn begin
        # dummy_user_id = UInt64(0)
        elapsed = @elapsed try
            symbol = "AAPL"
            ig_get_quote(symbol)
            # ig_save_portfolio(
            #     dummy_user_id, IgPortfolio(100, [IgHolding(symbol, 100, today(), 130)])
            # )
            # ig_load_portfolio(dummy_user_id)
            ig_ranking_table(Client("hey"))

            from_date, to_date = Date(2020, 1, 1), Date(2020, 12, 31)
            df = ig_historical_prices(symbol, from_date, to_date)
            @info "Warm up: charting"
            ig_chart(symbol, df.Date, df."Adj Close")
        catch ex
            @error "Warm up error: " ex
            Base.showerror(stdout, ex, catch_backtrace())
        finally
            # ig_remove_game(dummy_user_id)
        end
        @info "Completed warm up in $elapsed seconds"
    end
end
