module Storage

using Discord
using Discord: Snowflake
import ..PluginBase: get_storage, shutdown
using ..PluginBase
export AbstractStoragePlugin, set_default!, persist!

global _default_backend::Dict{AbstractPlugin, AbstractStoragePlugin}()
global _FALLBACK_END::AbstractStoragePlugin

abstract type AbstractStoragePlugin <: AbstractPlugin end

get_storage(m::Message, p::AbstractPlugin) = get_storage(m.guild_id, p, get!(_default_backend, p, _FALLBACK_END))

function get_storage(guild_id::Snowflake, p::AbstractPlugin, storage::AbstractStoragePlugin)
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

"Persist the storage object for next session"
function persist! end

"Load the storage object from last session"
function load! end

function init(p::AbstractStoragePlugin)
    load!(p)
    return true
end

function shutdown(p::AbstractStoragePlugin)
    persist!(p)
    return true
end

end
