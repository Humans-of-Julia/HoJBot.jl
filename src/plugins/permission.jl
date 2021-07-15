module Permission

using Discord: Snowflake
using ..PluginBase
using StructTypes

struct PermissionPlugin <: AbstractPlugin end

const PLUGIN = PermissionPlugin()

abstract type AbstractPermission end

function __init__()
    register!(PLUGIN)
end

PluginBase.has_access(guid::Snowflake, member::Member, perm::AbstractPermission) = has_access(guid, member.roles, perm)

function PluginBase.has_access(guid::Snowflake, roles::Vector{Snowflake}, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    return !isdisjoint(guildperms[perm], roles)
end

function PluginBase.has_access(guid::Snowflake, role::Snowflake, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    return role in guildperms[perm]
end

function PluginBase.grant!(guid::Snowflake, role::Snowflake, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    push!(guildperms[perm], role)
end

function PluginBase.revoke!(guid::Snowflake, role::Snowflake, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    delete!(guildperms[perm], role)
end

function PluginBase.create_storage(backend::AbstractPlugin, ::PermissionPlugin)
    return Dict{AbstractPermission, Set{Snowflake}}()
end

PluginBase.isenabled(guid::Snowflake, ::PermissionPlugin) = true

end
