module Permission

using Discord: Snowflake
import ..PluginBase: has_access, grant!, revoke!, create_storage
using ..PluginBase

struct PermissionPlugin <: AbstractPlugin end

const PLUGIN = PermissionPlugin()

abstract type AbstractPermission end


has_access(guid::Snowflake, member::Member, task::Functionality) = has_access(guid, member.roles, task)

function has_access(guid::Snowflake, roles::Vector{Snowflake}, perm::AbstractPermission)
    guildperms = get_storage(guid, PLUGIN)
    return !isdisjoint(guildperms[perm], roles)
end

function grant!(guid::Snowflake, role::Snowflake, perm::AbstractPermission)
    guildperms = PERMISSIONS[guid]
    push!(guildperms[perm], role)
    save(guid, guildperms)
end

function revoke!(guid::Snowflake, role::Snowflake, perm::AbstractPermission)
    guildperms = PERMISSIONS[guid]
    delete!(guildperms[perm], role)
    save(guid, guildperms)
end

function has_access(m::Message, )

end

function create_storage(::PermissionPlugin, ::AbstractStoragePlugin)
    return Dict{AbstractPermission, }
end

end
