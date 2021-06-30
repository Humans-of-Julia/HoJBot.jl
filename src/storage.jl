const DATAPATH = "data/"

@enum Persistence Volatile Filesystem Channel
construct_path(guild::Snowflake, plugin::Symbol; base=DATAPATH) = joinpath(base, string(guild), string(plugin)*".bin")

const STORAGE = Dict{Snowflake, GuildStorage}()

struct GuildStorage
    guild::Snowflake
    # tags::T
    # persistence::Dictionary{T, Persistence}
    value::Dictionary{Indices{Symbol}, PluginStorage}
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

function persist!(storage::GuildStorage)

end

function store!(storage::GuildStorage, plugin::Symbol, tag, value)
    storage[plugin][tag] = value
end

function request(storage::GuildStorage, plugin::Symbol, tag, Type)
    return storage[plugin][tag]
end
