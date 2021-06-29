# implement julia_commander for managing queues
module Queue

using Discord
import ..PluginBase

const SUBCOMMANDS = Dict{String, Function}()

register_subcommand!(keyword, func) = SUBCOMMANDS[keyword] = func

function handle_command(c::Client, m::Message, ::Val{:queue})
    # @info "julia_commander called"
    # @info "Message content" m.content m.author.username m.author.discriminator
    parts = split(m.content)
    @assert parts[1]==COMMAND_PREFIX * "q"
    subcommand = get(SUBCOMMANDS, parts[2], nothing)
    if subcommand !== nothing
        subcommand(c, m, parts[3:end]...)
    else
        reply(c, m, "Sorry, I don't understand the request; use `q help` to see what's possible")
    end
    return nothing
end

function sub_channel!(c::Client, m::Message, channel)

    #grant!(m.guild_id, Val(:queuechannel), channel)
end

function sub_join!(c::Client, m::Message, queue)

    reply(c, m, """You will have been added to $queue-queue""")
    return nothing
end

function sub_leave!(c::Client, m::Message, queue)
    
end

function sub_list(c::Client, m::Message, queue)
    
end

function sub_position(c::Client, m::Message)
    
end

function sub_pop!(c::Client, m::Message, queue)
    
end

function sub_create!(c::Client, m::Message, name, role)
    
end

function sub_remove!(c::Client, m::Message, queue)
    
end

function sub_help(c::Client, m::Message)
    # @info "Sending help for message" m.id m.author
    reply(c, m, """
        The `q` command manages the queues.

        Here is the list of all available `q` commands and their use:
        `q join! <queue>` adds user to queue
        `q leave! <queue>` removes user from queue
        `q list <queue>` lists the specified queue
        `q position` shows the current position in every queue
        `q pop! <name>` removes the user with the first position from the queue
        `q create! <name> <role>` creates a new queue that is managed by <role>
        `q channel! <channel>` set the channel that lists the queues
        `q remove! <name>` removes an existing queue
        `q help` returns this help
        """)
    return nothing
end

for sub in filter!(x->startswith(string(x), "sub"), names(@__MODULE__, all=true)) 
    register_subcommand!(string(sub)[5:end], getproperty(@__MODULE__, sub))
end

"""
q
    [manager]
    create #name [#role...] // legt neue Queue an
    remove #name
    
    [#role...]
    pop // entfernt den User mit der ersten Position von der Liste (zb nach Typing)
    
    [everyone]
    help // gibt Hilfe aus
    join #queue // fügt USER zur Liste hinzu
    leave #queue // entfernt USER von Liste
    list #queue // gibt Liste aus
    position // zeigt eigene Position in allen queues








"""
end
