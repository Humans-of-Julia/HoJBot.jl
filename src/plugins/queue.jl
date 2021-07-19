# implement julia_commander for managing queues
module Queue

using Discord
using Discord: Snowflake
using ..PluginBase

struct QueuePlugin <: AbstractPlugin end

PluginBase.identifier(::QueuePlugin) = "queue"

const PLUGIN = QueuePlugin()

struct ManageQueue <: AbstractPermission
    queue::Symbol
end

struct CreateQueue <: AbstractPermission end

function __init__()
    register!(PLUGIN)
end

qsym(name::AbstractString) = Symbol(lowercase(name))

function PluginBase.initialize!(client::Client, ::QueuePlugin)
    add_command!(client, :q, handle)
    return true
end

function PluginBase.create_storage(backend::AbstractPlugin, ::QueuePlugin)
    return Dict{Symbol,Vector{Snowflake}}()
end

function handle(c::Client, m::Message)
    isenabled(m.guild_id, m.channel_id, PLUGIN) || return
    args = split(m.content)
    if length(args) < 2
        reply(c, m, "you need a subcommand")
        return
    end
    subcommand = args[2]
    if subcommand == "join!"
        reply(c, m, sub_join!(m.guild_id, m.author.id, args[3]))
    elseif subcommand == "leave!"
        reply(c, m, sub_leave!(m.guild_id, m.author.id, args[3]))
    elseif subcommand == "list"
        sub_list(c, m, args[3])
    elseif subcommand == "position"
        reply(c, m, sub_position(m.guild_id, m.author.id))
    elseif subcommand == "pop!"
        if !is_permitted(c, m, ManageQueue(Symbol(args[3])))
            reply(c, m, "you are not allowed to manage queue $(args[3])")
        else
            reply(c, m, sub_pop!(m.guild_id, args[3]))
        end
    elseif subcommand == "create!"
        if !is_permitted(c, m, CreateQueue())
            reply(c, m, "you are not allowed to create queues")
        elseif length(args)<4
            reply(c, m, "missing arguments")
        elseif (queuename=args[3]; role=args[4]; role[1]!='<' || role[2]!='@' || role[3]!='&' || role[end]!='>')
            reply(c, m, "invalid role")
        else
            reply(c, m, sub_create!(m.guild_id, queuename, parse(Snowflake, role[4:end-1])))
        end
    elseif subcommand == "remove!"
        if !is_permitted(c, m, CreateQueue())
            reply(c, m, "you are not allowed to remove queues")
        else
            reply(c, m, sub_remove!(m.guild_id, args[3]))
        end
    else
        reply(c, m, help_message())
    end
end

# (Val{:q}, Val{:join!}, queuename::String)#`q join! <queue>` adds user to queue
# (Val{:q}, Val{:leave!}, queuename::String)# `q leave! <queue>` removes user from queue
# (Val{:q}, Val{:list}, queuename::String)# `q list <queue>` lists the specified queue
# (Val{:q}, Val{:position})# `q position` shows the current position in every queue
# (Val{:q}, Val{:pop!}, queuename::String)# `q pop! <name>` removes the user with the first position from the queue
# (Val{:q}, Val{:create!}, queuename::String, role::Snowflake)# `q create! <name> <role>` creates a new queue that is managed by <role>
# (Val{:q}, Val{:remove!}, queuename::String)# `q remove! <name>` removes an existing queue
# (Val{:q}, Val{:help})# `q help` returns this help



function sub_join!(guid::Snowflake, user::Snowflake, queuename::AbstractString)
    pluginstorage = get_storage(guid, PLUGIN)
    queue = get(pluginstorage, qsym(queuename), nothing)
    if queue===nothing
        return "Queue $queuename does not exist."
    elseif (pos=indexin(user, queue)[])!==nothing
        return "You already are enqueued. Your current position is: $pos"
    else    
        push!(queue, user)
        return "You have been added to $queuename-queue. Your current position is: $(length(queue))"
    end
end

function sub_leave!(guid::Snowflake, user::Snowflake, queuename::AbstractString)
    pluginstorage = get_storage(guid, PLUGIN)
    queue = get(pluginstorage, qsym(queuename), nothing)
    if queue===nothing
        return "Queue $queuename does not exist."
    elseif (pos=indexin(user, queue)[])===nothing
        return "You haven't been in the queue. Nothing changed."
    else    
        deleteat!(queue, pos)
        return "You left $queuename."
    end
end

function sub_list(c::Client, m::Message, queuename::AbstractString)
    pluginstorage = get_storage(m, PLUGIN)
    queue = get(pluginstorage, qsym(queuename), nothing)
    if queue===nothing
        reply(c, m, """Queue $queuename does not exist.""")
    else
        msg = reply(c, m, "placeholder for non-ping")
        newtext = join(("$pos: <@$name>" for (pos, name) in enumerate(queue)), "\r\n")
        fetched = fetchval(msg)
        edit_message(c, fetched.channel_id, fetched.id, content=newtext)
    end
    return nothing
end

function sub_position(guid::Snowflake, user::Snowflake)
    pluginstorage = get_storage(guid, PLUGIN)
    queues = keys(pluginstorage)
    return join(("$q: position $(only(indexin(user, pluginstorage[q])))" for q in queues), "\r\n")
end

function sub_pop!(guid::Snowflake, queuename::AbstractString)
    pluginstorage = get_storage(guid, PLUGIN)
    queue = get(pluginstorage, qsym(queuename), nothing)
    if queue===nothing
        return "Queue $queuename does not exist."
    else
        tip = popfirst!(queue)
        return "<@$tip> is no more part of the queue"
    end
end

function sub_create!(guid::Snowflake, queuename::AbstractString, role::Snowflake)
    pluginstorage = get_storage(guid, PLUGIN)
    qsymbol = qsym(queuename)
    queue = get(pluginstorage, qsymbol, nothing)
    if queue !== nothing
        return "Queue $queuename already exists."
    else
        pluginstorage[qsymbol] = Snowflake[]
        grant!(guid, role, ManageQueue(Symbol(queuename)))
        return "Queue $queuename created. <@&$role> can manage it."
    end
end

function sub_remove!(guid::Snowflake, queuename::AbstractString)
    pluginstorage = get_storage(guid, PLUGIN)
    delete!(pluginstorage, qsym(queuename))
    revokeall!(guid, ManageQueue(Symbol(queuename)))
    return "Queue $queuename deleted."
end

function help_message()
    return """
    The `q` command manages the queues.

    Here is the list of all available `q` commands and their use:
    `q join! <queue>` adds user to queue
    `q leave! <queue>` removes user from queue
    `q list <queue>` lists the specified queue
    `q position` shows the current position in every queue
    `q pop! <queue>` removes the user with the first position from the queue
    `q create! <queue> <role>` creates a new queue that is managed by <role>
    `q remove! <queue>` removes an existing queue
    `q help` returns this help
    """
end

end
