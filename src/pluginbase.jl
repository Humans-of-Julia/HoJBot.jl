module PluginBase

export AbstractPlugin, AbstractPermission, is_permitted, grant!, revoke!, revokeall!, isenabled
export register!, initialize!, shutdown!, create_storage #extend everwhere
export get_storage #extend in new storage backends
export identifier, plugin_by_identifier

using Discord

abstract type AbstractPlugin end

abstract type AbstractPermission end

const INSTANCES = Dict{String, AbstractPlugin}()
const LOADED = AbstractPlugin[]

function register!(p::AbstractPlugin)
    INSTANCES[identifier(p)] = p
end

"""
    initialize!(client::Client, ::AbstractPlugin)::Bool
Is called to initialize the supplied plugin and returns whether loading was completed successfully or should be continued later
"""
function initialize!(client::Client, ::AbstractPlugin)
    return true
end

"""
initialize!(client::Client)::Bool
Is called to initiate initialization of all plugins and returns whether it was completed successfully
"""
function initialize!(client::Client)
    isempty(LOADED) || return
    waiting = collect(values(INSTANCES))
    while !isempty(waiting)
        current = popfirst!(waiting)
        # if isabstracttype(current)
            # append!(waiting, subtypes(current))
        # else
            # pluginstance = current()
        success = initialize!(client, current)
        if success
            push!(LOADED, current)
            @info "$(identifier(current)) loaded"
        else
            push!(waiting, current)
        end
        # end
    end
end

"""
    shutdown!(::AbstractPlugin)::Bool
Is called before the server shutdowns and returns whether stopping was successful or should be deferred to a later time
"""
function shutdown!(::AbstractPlugin)
    return true
end

"""
    shutdown!()::Bool
Is called to initiate the shutdown of the plugins when the server is shutdown. Returns the success to do so.
"""
function shutdown!()
    while !isempty(LOADED)
        current = popfirst!(LOADED)
        success = shutdown!(current)
        if success
            id = identifier(current)
            delete!(INSTANCES, id)
            @info "$id unloaded"
        else
            push!(LOADED, current)
        end
    end
    return isempty(LOADED)
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

"DON'T confuse with has_permission"
function is_permitted end

function grant! end

function revoke! end

function revokeall! end

"""
    isenabled(guid::Snowflake, ::AbstractPlugin)
Says whether the plugin is enabled on a given server
"""
function isenabled end

end
