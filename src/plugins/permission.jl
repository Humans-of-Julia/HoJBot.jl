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

function PluginBase.is_permitted(client::Client, guid::Snowflake, roles::Vector{Snowflake}, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    return !isdisjoint(guildperms[perm], roles)
end

function PluginBase.is_permitted(client::Client, guid::Snowflake, role::Snowflake, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    return role in guildperms[perm]
end

function PluginBase.grant!(client::Client, guid::Snowflake, role::Snowflake, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    push!(guildperms[perm], role)
end

function PluginBase.revoke!(client::Client, guid::Snowflake, role::Snowflake, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    delete!(guildperms[perm], role)
end
function check_admin(client::Client, m::Message)
    guild = Discord.get_guild(client, m.guild_id)
    channel = Discord.get_channel(client, m.channel_id)
    perms = Discord.permissions_in(m.member, guild, channel)
    return Discord.has_permission(perms, PERM_ADMINISTRATOR)
end

function PluginBase.create_storage(backend::AbstractPlugin, ::PermissionPlugin)
    return Dict{AbstractPermission, Set{Snowflake}}()
end

end
