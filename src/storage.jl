const DATAPATH = "data/"

@enum Persistence Volatile Filesystem Channel

import .PluginBase: request, persist!, store!

construct_path(guild::Snowflake, plugin::Symbol; base=DATAPATH) = joinpath(base, string(guild), string(plugin)*".bin")

const PluginStorage = Dict{Symbol, Any}
struct GuildStorage
    guild::Snowflake
    # tags::T
    # persistence::Dictionary{T, Persistence}
    plugins::Dictionary{Symbol, PluginStorage}
    GuildStorage(guildid::Snowflake) = new(guildid, Dictionary{Symbol,PluginStorage}())
end

const STORAGE = Dict{Snowflake, GuildStorage}()

request(message::Message) = request(message.guild_id)

function request(guid::Snowflake)
    guildstore = get(STORAGE, guid, nothing)
    if guildstore === nothing
        ensurepath!(construct_path(guid, Symbol()))
        STORAGE[guid] = guildstore = GuildStorage(guid)
    end
    return guildstore
end

function request(storage::GuildStorage, plugin::Symbol; create=true)
    pluginstorage = get(storage.value, plugin, nothing)
    if pluginstorage === nothing && create
        pluginstorage = PluginStorage()
        set!(storage.value, plugin, pluginstorage)
    end
    return pluginstorage
end

function persist!(storage::GuildStorage)

end

function _exists(storage::GuildStorage, plugin::Symbol, tag)
    pluginstorage = get(storage.plugins, plugin, nothing)
    pluginstorage === nothing && return false
    return get(pluginstorage, tag, nothing)!==nothing
end

function store!(storage::GuildStorage, plugin::Symbol, tag, value; overwrite=false)
    if !overwrite && _exists(storage, plugin, tag)
        @warn "catched illegal write"
        return nothing
    end
    storage.plugins[plugin][tag] = value
    return nothing
end


function request(storage::GuildStorage, plugin::Symbol, tag, type::Type{T})::Tuple{Bool,Union{T,Nothing}} where T
    pluginstorage = get(storage.plugins, plugin, nothing)
    pluginstorage === nothing && return (false, nothing)
    tagvalue = get(pluginstorage, tag, nothing)
    tagvalue === nothing && return (false, nothing)
    return (true, tagvalue)
end
