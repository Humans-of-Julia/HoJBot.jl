module Storage

using Discord
using Discord: Snowflake
using ..PluginBase
export AbstractStoragePlugin, set_default!

global _default_backend::Dict{AbstractPlugin, AbstractStoragePlugin}()
global _FALLBACK_END::AbstractStoragePlugin

abstract type AbstractStoragePlugin <: AbstractPlugin end

PluginBase.isenabled(guid::Snowflake, ::AbstractStoragePlugin) = true

PluginBase.identifier(p::AbstractStoragePlugin) = string(typeof(p))

PluginBase.get_storage(m::Message, args...) = get_storage(m.guild_id, args...)

function PluginBase.get_storage(guild_id::Snowflake, p::AbstractPlugin, storage::AbstractStoragePlugin=get!(_default_backend, p, _FALLBACK_END))
    @warn "Storage plugin $plugin for $p not found, defaulting..."
    default = get(_default_backend, p, _FALLBACK_END)
    if storage == default
        @error "default backend is not availabled"
    end
    return get_storage(guild_id, p, default)
end

function set_default!(p::AbstractPlugin, storage::AbstractStoragePlugin)
    _default_storage[p] = storage
end

function set_default!(storage::AbstractStoragePlugin)
    global _FALLBACK_END = storage
end

end
