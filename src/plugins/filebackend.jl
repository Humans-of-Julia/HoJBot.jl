module FileStorage

const DATAPATH = "data/"

using Discord
using Discord: Snowflake
using ..PluginBase
using ..Storage
using JSON3
using Dictionaries
using ..HoJBot: ensurepath!

struct FileBackend <: AbstractStoragePlugin end

const PLUGIN = FileBackend()

construct_path(guild::Snowflake, plugin::AbstractPlugin; base=DATAPATH) = joinpath(base, string(guild), identifier(plugin)*".bin")

# const PluginStorage = Dict{Symbol, Any}

#Predefined Plugin Namespaces: Common Permission
struct GuildStorage
    guild::Snowflake
    # tags::T
    # persistence::Dictionary{T, Persistence}
    plugins::Dictionary{AbstractPlugin, Any}
    GuildStorage(guildid::Snowflake) = new(guildid, Dictionary{AbstractPlugin,Any}())
end

const STORAGE = Dict{Snowflake, GuildStorage}()

function __init__()
    register!(PLUGIN)
    set_default!(PLUGIN)
end

function PluginBase.initialize!(client::Client, p::AbstractStoragePlugin)
    # loading on demand
    return true
end

function PluginBase.get_storage(guid::Snowflake, p::AbstractPlugin, ::FileBackend;force_load=false)
    guildstore = get(STORAGE, guid, nothing)
    if guildstore === nothing
        STORAGE[guid] = guildstore = GuildStorage(guid)
    end
    pluginstorage = get(guildstore.plugins, p, nothing)
    if pluginstorage === nothing || force_load
        pluginstorage = create_storage(PLUGIN, p)
        set!(guildstore.plugins, p, pluginstorage)
        target = construct_path(guid, p)
        if !isfile(target)
            @warn "tried to load non-existing storage"
        else
            open(target) do io
                StructTypes.constructfrom!(pluginstorage, JSON3.read(io))
            end
        end
    end
    return pluginstorage
end

function persist!(guid::Snowflake, p::AbstractPlugin)
    guildstore = get(STORAGE, guid, nothing)
    guildstore !== nothing || return
    pluginstore = get(guildstore.plugins, p, nothing)
    pluginstore !== nothing || return
    open(ensurepath!(construct_path(guid, p)), write=true) do io
        JSON3.write(io, pluginstore)
    end
end

function PluginBase.shutdown!(::FileBackend)
    for (guid, storage) in pairs(STORAGE)
        for p in keys(storage.plugins)
            persist!(guid, p)
        end
    end
    return true
end

end
