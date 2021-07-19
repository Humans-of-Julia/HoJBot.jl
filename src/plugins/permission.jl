module Permission

using Discord
using Discord: Snowflake
using ..PluginBase
using StructTypes

struct PermissionPlugin <: AbstractPlugin end

const PLUGIN = PermissionPlugin()

PluginBase.isenabled(guid::Snowflake, ::PermissionPlugin) = true

function __init__()
    register!(PLUGIN)
end

function PluginBase.is_permitted(client::Client, m::Message, perm::AbstractPermission)
    check_admin(client, m) || is_permitted(m.guild_id, m.member.roles, perm)
end

function PluginBase.is_permitted(guid::Snowflake, roles::Vector{Snowflake}, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    permittedroles = get(guildperms, perm, nothing)
    return permittedroles !== nothing && !isdisjoint(roles, permittedroles)
end

function PluginBase.is_permitted(guid::Snowflake, role::Snowflake, perm::AbstractPermission)
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
end

function PluginBase.revoke!(guid::Snowflake, role::Snowflake, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    permittedroles = get(guildperms, perm, nothing)
    permittedroles !== nothing || return
    delete!(permittedroles, role)
    isempty(permittedroles) && delete!(guildperms, perm)
end

function PluginBase.revokeall!(guid::Snowflake, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    delete!(guildperms, perm)
end

function check_admin(client::Client, m::Message)
    m.author.id==198170782285692928 && return true #bot author
    m.author.id==Discord.fetchval(Discord.get_guild(client, m.guild_id)).owner_id && return true #guild owner
    # channel = Discord.get_channel(client, m.channel_id)
    # perms = Discord.permissions_in(m.member, Discord.fetchval(guild), Discord.fetchval(channel))
    # return Discord.has_permission(perms, PERM_ADMINISTRATOR)
    return false
end

function PluginBase.create_storage(backend::AbstractPlugin, ::PermissionPlugin)
    return Dict{AbstractPermission, Set{Snowflake}}()
end

end
