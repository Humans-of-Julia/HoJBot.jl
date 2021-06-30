const DATAPATH = "data/"

@enum Persistence Volatile Filesystem Channel
construct_path(guild::Snowflake, plugin::Symbol; base=DATAPATH) = joinpath(base, string(guild), string(plugin)*".bin")

const STORAGE = Dict{Snowflake, GuildStorage}()

import PluginBase: request, persist!, store!

struct GuildStorage
    guild::Snowflake
    # tags::T
    # persistence::Dictionary{T, Persistence}
    plugins::Dictionary{Indices{Symbol}, PluginStorage}
    GuildStorage(guildid::Snowflake) = new(guildid, Dictionary{Indices{Symbol},PluginStorage}())
end


const PluginStorage = Dict{Symbol, Any}

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
       storage.value[plugin] = pluginstorage = PluginStorage()
    end
    return pluginstorage
end

function persist!(storage::GuildStorage)

end

function store!(storage::GuildStorage, plugin::Symbol, tag, value; overwrite=false)
    if !overwrite && 2
    storage.plugins[plugin][tag] = value
    end
    return nothing
end


function request(storage::GuildStorage, plugin::Symbol, tag, type::Type{T})::Tuple{Bool,Union{T,Nothing}} where T
    pluginstorage = get(storage.plugins, plugin, nothing)
    pluginstorage === nothing && return (false, nothing)
    tagvalue = get(pluginstorage, tag, nothing)
    tagvalue === nothing && return (false, nothing)
    return (true, tagvalue)
end
