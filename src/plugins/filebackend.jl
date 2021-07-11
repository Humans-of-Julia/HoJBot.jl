module FileStorage

const DATAPATH = "data/"

import ..PluginBase: get_storage
using ..PluginBase
import ..Storage: load!, persist!
using ..Storage
using JSON3
using Dictionaries

struct FileBackend <: AbstractStoragePlugin end

const PLUGIN = FileBackend()

function __init__()
    set_default!(FileBackend())
end

construct_path(guild::Snowflake, plugin::Symbol; base=DATAPATH) = joinpath(base, string(guild), string(plugin)*".bin")

# const PluginStorage = Dict{Symbol, Any}

#Predefined Plugin Namespaces: Common Permission
struct GuildStorage
    guild::Snowflake
    # tags::T
    # persistence::Dictionary{T, Persistence}
    plugins::Dictionary{Symbol, Any}
    GuildStorage(guildid::Snowflake) = new(guildid, Dictionary{Symbol,Any}())
end

const STORAGE = Dict{Snowflake, GuildStorage}()

function get_storage(guid::Snowflake, p::AbstractPlugin, backend::FileBackend)
    guildstore = get(STORAGE, guid, nothing)
    pn = plugin_name(p)
    if guildstore === nothing
        ensurepath!(construct_path(guid, pn))
        STORAGE[guid] = guildstore = GuildStorage(guid)
    end
    pluginstorage = get(guildstore.plugins, pn, nothing)
    if pluginstorage === nothing
        pluginstorage = create_storage(p, backend)
        set!(storage.plugins, pn, pluginstorage)
    end
    return pluginstorage
end

persist!(guid::Snowflake, p::AbstractPlugin, backend::FileBackend) = _persist!(guid, plugin_name(p))

function _persist!(guid::Snowflake, p::Symbol)
    target = construct_path(guid, p)
    guildstore = get(STORAGE, guid, nothing)
    guildstore !== nothing || return
    pluginstore = get(guildstore, p, nothing)
    pluginstore !== nothing || return
    JSON3.write(target, pluginstore)
end

function persist!(::FileBackend)
    for (guid, storage) in pairs(STORAGE)
        for (pluginsym, strut) in storage
            _persist!(guid, pluginsym)
        end
    end
end

plugin_name(p::AbstractPlugin) = Symbol(typeof(p))

end
