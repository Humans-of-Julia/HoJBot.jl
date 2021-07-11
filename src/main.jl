# Package initiation hook
function __init__()
    # Unfortunately, the default GR backend does not work well with
    # offline plotting (see this issue https://github.com/JuliaPlots/Plots.jl/issues/2127).
    # So, we will use PyPlot backend instead.
    start_bot()
end

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
    run_duration = Minute(365 * 24 * 60),  # run for a very long time by default
)
    @info "Starting bot... command prefix = $COMMAND_PREFIX"
    global client = Client(
        ENV["HOJBOT_DISCORD_TOKEN"];
        presence=(game=(name="HoJ", type=AT_GAME),),
        prefix=COMMAND_PREFIX,
    )
    loaded_plugins = init_plugins!()
    init_handlers!(client, handlers)
    init_commands!(client, commands)
    # add_help!(client; help = help_message())
    open(client)
    auto_shutdown(client, run_duration, "SHUTDOWN")
    wait(client)
end

function init_plugins!()
    initialized = Set{PluginBase.AbstractPlugin}()
    waiting = Type{PluginBase.AbstractPlugin}[PluginBase.AbstractPlugin]
    while !isempty(waiting)
        current = pop!(waiting)
        if isabstracttype(current)
            append!(waiting, subtypes(current))
        else
            pluginstance = current()
            success = PluginBase.init(pluginstance, initialized)
            if success
                push!(initialized, pluginstance)
            else
                push!(waiting, current)
            end
        end
    end
    return initialized
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
