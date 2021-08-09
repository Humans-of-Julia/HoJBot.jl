module Permission

using Discord
using Discord: Snowflake
using ..PluginBase
using StructTypes

struct PermissionPlugin <: AbstractPlugin end

const PLUGIN = PermissionPlugin()

struct AdminPermission <: AbstractPermission end
struct BotAuthorPermission <: AbstractPermission end

PluginBase.isenabled(guid::Snowflake, ::PermissionPlugin) = true

function __init__()
    register!(PLUGIN, permissions=(AdminPermission,BotAuthorPermission))
end

function PluginBase.initialize!(client::Client, ::PermissionPlugin)
    add_command!(client, :permission, handle)
    return true
end

#,permission grant! admin @Role
#,permission revoke! admin @Role
#,permission is_permitted admin @Role
function handle(c::Client, m::Message)
    isenabled(m.guild_id, m.channel_id, PLUGIN) || return
    ispermitted(c, m, AdminPermission()) || return
    args = split(m.content)
    if length(args) < 3
        reply(c, m, "Unknown command")
        return
    end
    subcommand = args[2]
    permtyp = lookup(args[3])
    if permtyp===nothing || !(permtyp <: AbstractPermission)
        reply(c, m, "$(args[3]) is an invalid permission identifier")
    elseif !isdefined(permtyp, :instance)
        reply(c, m, "$(args[3]) is too complex for generic support")
    elseif (perm = permtyp.instance; false)
    elseif subcommand == "list"
        reply(c, m, list(m.guild_id, perm))
    elseif (role=role_id(args[4]); role===nothing)
        reply(c, m, "$(args[4]) is an invalid role")
    elseif subcommand == "grant!"
        grant!(m.guild_id, role, perm)
        reply(c, m, list(m.guild_id, perm))
    elseif subcommand == "revoke!"
        revoke!(m.guild_id, role, perm)
        reply(c, m, list(m.guild_id, perm))
    elseif subcommand == "is_permitted"
        reply(c, m, string(ispermitted(m.guild_id, role, perm)))
    else
        reply(c, m, "Unknown command")
    end
end

function PluginBase.ispermitted(client::Client, m::Message, perm::AbstractPermission, reply_if_not_allowed)
    allowed = ispermitted(client, m, perm)
    allowed || reply(client, m, reply_if_not_allowed)
    return allowed
end

function PluginBase.ispermitted(client::Client, m::Message, perm::AbstractPermission)
    isadmin = ispermitted(client, m, AdminPermission())
    allowed = _ispermitted(m.guild_id, m.member.roles, perm)
    @info "permission is being checked" author=m.author.id admin=isadmin roles=join(m.member.roles, ", ") permission=perm success=allowed
    return #=isadmin ||=# allowed
end

function _ispermitted(guid::Snowflake, roles::Vector{Snowflake}, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    permittedroles = get(guildperms, perm, nothing)
    return permittedroles !== nothing && !isdisjoint(roles, permittedroles)
end

function _ispermitted(guid::Snowflake, role::Snowflake, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    permittedroles = get(guildperms, perm, nothing)
    return permittedroles !== nothing && role in permittedroles
end

function PluginBase.grant!(guid::Snowflake, role::Snowflake, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    permittedroles = get(guildperms, perm, nothing)
    if permittedroles===nothing
        guildperms[perm] = Set{Snowflake}(role)
    else
        push!(permittedroles, role)
    end
    return true
end

function PluginBase.revoke!(guid::Snowflake, role::Snowflake, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    permittedroles = get(guildperms, perm, nothing)
    permittedroles !== nothing || return
    delete!(permittedroles, role)
    isempty(permittedroles) && delete!(guildperms, perm)
    return true
end

function PluginBase.revokeall!(guid::Snowflake, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    delete!(guildperms, perm)
end

function list(guid::Snowflake, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    permittedroles = get(guildperms, perm, nothing)
    return permittedroles===nothing ? "no permissions set" : join(permittedroles, ", ")
end

function PluginBase.create_storage(backend::AbstractPlugin, ::PermissionPlugin)
    return Dict{AbstractPermission, Set{Snowflake}}()
end

###### BotAuthor persistance

function PluginBase.ispermitted(client::Client, m::Message, perm::BotAuthorPermission)
    return m.author.id==198170782285692928
end

function PluginBase.ispermitted(client::Client, something, perm::BotAuthorPermission)
    return false
end

###### Admin persistance

function PluginBase.ispermitted(client::Client, m::Message, perm::AdminPermission)
    ispermitted(client, m, BotAuthorPermission()) && return true #bot author
    _ispermitted(m.guild_id, m.member.roles, AdminPermission()) && return true #admin role
    m.author.id==Discord.fetchval(Discord.get_guild(client, m.guild_id)).owner_id && return true #guild owner
    # channel = Discord.get_channel(client, m.channel_id)
    # perms = Discord.permissions_in(m.member, Discord.fetchval(guild), Discord.fetchval(channel))
    # return Discord.has_permission(perms, PERM_ADMINISTRATOR)
    return false
end

end
