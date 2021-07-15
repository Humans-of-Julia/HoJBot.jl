module PluginBase

export AbstractPlugin, has_permission, grant!, revoke!, isenabled
export register!, init, shutdown, create_storage #extend everwhere
export handle_command, handle_event, help #extend in new features
export get_storage #extend in new storage backends
export identifier, plugin_by_identifier

using StructTypes

const INSTANCES = Dict{String, AbstractPlugin}()
const LOADED = AbstractPlugin[]

abstract type AbstractPlugin end

StructTypes.StructType(::Type{<:AbstractPlugin}) = StructTypes.CustomStruct()
StructTypes.lowertype(::Type{<:AbstractPlugin}) = String
StructTypes.lower(x::AbstractPlugin) = identifier(x)
StructTypes.construct(::Type{AbstractPlugin}, x::String) = plugin_by_identifier(x)

function register!(p::AbstractPlugin)
    INSTANCES[identifier(p)] = p
end

function initialize(c::Client)
    isempty(LOADED) || return
    waiting = collect(values(INSTANCES))
    while !isempty(waiting)
        current = popfirst!(waiting)
        # if isabstracttype(current)
            # append!(waiting, subtypes(current))
        # else
            # pluginstance = current()
        success = initialize(client, current)
        if success
            push!(LOADED, current)
        else
            push!(waiting, current)
        end
        # end
    end
end

function shutdown_plugins!()
    waiting = values(LOADED)
    while !isempty(waiting)
        current = popfirst!(waiting)
        success = shutdown(current)
        if success
            delete!(LOADED, identifier(current))
        else
            push!(waiting, current)
        end
    end
    isempty(LOADED) || @warn "shutting down didn't work properly"
end

function identifier(p::AbstractPlugin)
    sym = string(typeof(p))
    if !endswith(sym, "Plugin")
        @warn "$p doesn't use type name formatting, customize identifier function"
    end
    return convert(String, sym[1:end-6])
end

plugin_by_identifier(s) = get(INSTANCES, string(s), nothing)

"""
initialize(client::Client, ::AbstractPlugin)::Bool

Is called to init the supplied plugin and returns whether loading was completed successfully or should be continued later
"""
function initialize(client::Client, ::AbstractPlugin)
    return true
end

"""
    shutdown(::AbstractPlugin)::Bool
Is called before the server shutdowns and returns whether stopping was successful
"""
function shutdown end

"Entry point for a new command plugin, only triggers on MessageCreate"
function handle_command end

"Entry point for a new observer plugin, triggers on almost all events related to text chat"
function handle_event end

"""
    help(::AbstractPlugin, args...; singleline=false)
Returns the help for the plugin. Setting singleline to true returns a single line info for aggregating the overall help
"""
function help end

"""
    create_storage(backend::AbstractPlugin, plugin::AbstractPlugin)

Returns an initialized plugin storage. Defaults to a Symbol->Any Dict

Defined by: each plugin that needs storage in any backend
"""
function create_storage(backend::AbstractPlugin, plugin::AbstractPlugin)
    return Dict{Symbol, Any}()
end

"Request the plugin storage object"
function get_storage end

function has_permission end

function grant! end

function revoke! end

"""
    isenabled(guid::Snowflake, ::AbstractPlugin)
Says whether the plugin is enabled on a given server
"""
function isenabled end

end
