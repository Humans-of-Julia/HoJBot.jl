# implement julia_commander for managing queues
module Queue

using Discord
using Discord: Snowflake
using ..PluginBase

struct QueuePlugin <: AbstractPlugin end

PluginBase.identifier(::QueuePlugin) = "queue"

const PLUGIN = QueuePlugin()

struct CreateQueue <: AbstractPermission end
struct ManageQueue <: AbstractPermission
    queue::Symbol
end
ManageQueue(q::AbstractString) = ManageQueue(qsym(q))

function __init__()
    register!(PLUGIN, permissions=(CreateQueue, ManageQueue))
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
    @info "on the go"
    subcommand = args[2]
    if subcommand == "position"
    reply(c, m, sub_position(m.guild_id, m.author.id))
    elseif subcommand == "help"
        reply(c, m, help_message())
    elseif length(args)<3
        reply(c, m, "missing queue argument")
    elseif (queuename=args[3]; false)
    elseif subcommand == "join!"
        reply(c, m, sub_join!(m.guild_id, m.author.id, queuename))
    elseif subcommand == "leave!"
        reply(c, m, sub_leave!(m.guild_id, m.author.id, queuename))
    elseif subcommand == "list"
        ret = sub_list(m.guild_id, queuename)
        reply(c, m, ret; allowed_mentions=(parse=(),))
    elseif subcommand == "pop!"
        if ispermitted(c, m, ManageQueue(queuename), "you are not allowed to manage queue $queuename")
            reply(c, m, sub_pop!(m.guild_id, queuename))
        end
    elseif subcommand == "delete!"
        if ispermitted(c, m, CreateQueue(), "you are not allowed to delete queues")
            reply(c, m, sub_delete!(m.guild_id, queuename))
        end
    elseif length(args)<4
        reply(c, m, "missing role argument")
    elseif (role=role_id(args[4]); role===nothing)
        reply(c, m, "invalid role")
    elseif subcommand == "create!"
        if ispermitted(c, m, CreateQueue(), "you are not allowed to create queues")
            reply(c, m, sub_create!(m.guild_id, queuename, role))
        end
    else
        reply(c, m, help_message())
    end
end

# (Val{:q}, Val{:join!}, queuename::String)#`q join! <queue>` adds user to queue
# (Val{:q}, Val{:leave!}, queuename::String)# `q leave! <queue>` deletes user from queue
# (Val{:q}, Val{:list}, queuename::String)# `q list <queue>` lists the specified queue
# (Val{:q}, Val{:position})# `q position` shows the current position in every queue
# (Val{:q}, Val{:pop!}, queuename::String)# `q pop! <name>` deletes the user with the first position from the queue
# (Val{:q}, Val{:create!}, queuename::String, role::Snowflake)# `q create! <name> <role>` creates a new queue that is managed by <role>
# (Val{:q}, Val{:delete!}, queuename::String)# `q delete! <name>` deletes an existing queue
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

function sub_list(guid::Snowflake, queuename::AbstractString)
    pluginstorage = get_storage(guid, PLUGIN)
    queue = get(pluginstorage, qsym(queuename), nothing)
    if queue===nothing
        return """Queue $queuename does not exist."""
    else
        return join(("$pos: <@$name>" for (pos, name) in enumerate(queue)), "\r\n")
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
        grant!(guid, role, ManageQueue(qsymbol))
        return "Queue $queuename created. <@&$role> can manage it."
    end
end

function sub_delete!(guid::Snowflake, queuename::AbstractString)
    pluginstorage = get_storage(guid, PLUGIN)
    qsymbol = qsym(queuename)
    delete!(pluginstorage, qsymbol)
    revokeall!(guid, ManageQueue(qsymbol))
    return "Queue $queuename deleted."
end

function help_message()
    return """
    The `q` command manages the queues.

    Here is the list of all available `q` commands and their use:
    `q join! <queue>` adds user to queue
    `q leave! <queue>` deletes user from queue
    `q list <queue>` lists the specified queue
    `q position` shows the current position in every queue
    `q pop! <queue>` deletes the user with the first position from the queue
    `q create! <queue> <role>` creates a new queue that is managed by <role>
    `q delete! <queue>` deletes an existing queue
    `q help` returns this help
    """
end

end
