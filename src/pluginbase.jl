module PluginBase

export AbstractPlugin, AbstractPermission, ispermitted, grant!, revoke!, revokeall!, isenabled
export register!, initialize!, shutdown!, create_storage #extend everwhere
export get_storage #extend in new storage backends
export identifier, lookup

using Discord
include("helpers.jl")

abstract type AbstractPlugin end

abstract type AbstractPermission end

const INSTANCES = Dict{String, AbstractPlugin}()
const PERMISSIONS = Dict{String, Type{<:AbstractPermission}}()

const LOADED = AbstractPlugin[]

function pluginmap()
    NamedTuple((Symbol(k), typeof(v))  for (k,v) in pairs(INSTANCES))
end

function permissionmap()
    NamedTuple((Symbol(k), v)  for (k,v) in pairs(PERMISSIONS))
end

function register!(plug::AbstractPlugin; permissions=nothing)
    INSTANCES[lowercase(identifier(plug))] = plug
    if permissions!==nothing
        for perm in permissions
            id = identifier(plug, perm)
            PERMISSIONS[id] = perm
        end
        
    end
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
    waiting = collect(setdiff(values(INSTANCES),LOADED))
    while !isempty(waiting)
        current = popfirst!(waiting)
        # if isabstracttype(current)
            # append!(waiting, subtypes(current))
        # else
            # pluginstance = current()
        try
            success = initialize!(client, current)
            if success
                push!(LOADED, current)
                @info "$(identifier(current)) loaded"
            else
                push!(waiting, current)
            end
        catch e
            @warn e
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
        try
            success = shutdown!(current)
            if success
                id = lowercase(identifier(current))
                @info "$id unloaded"
            else
                push!(LOADED, current)
            end
        catch e
            @warn e stacktrace(catch_backtrace())
        end
    end
    return isempty(LOADED)
end

function identifier(p::AbstractPlugin)
    sym = lowercase(string(typeof(p).name.name))
    if !endswith(sym, "plugin")
        @warn "$p doesn't use type name formatting, customize identifier function"
    end
    return convert(String, sym[1:end-6])
end

function identifier(p::AbstractPlugin, perm::Type{T}) where {T<:AbstractPermission}
    sym = identifier(p)*'.'*lowercase(string(T.name.name))
    if endswith(sym, "permission")
        return convert(String, sym[1:end-10])
    else
        # @warn "$perm doesn't use type name formatting, customize identifier function"
        return convert(String, sym)
    end
end

function lookup(s)
    id = lowercase(string(s))
    idx = findfirst(==('.'), id)
    if idx===nothing
        return get(INSTANCES, id, nothing)
    else
        return get(PERMISSIONS, id, nothing)
    end
end

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
function create_storage end

"Request the plugin storage object"
function get_storage end

"DON'T confuse with has_permission"
function ispermitted end

function grant! end

function revoke! end

function revokeall! end

"""
    isenabled(guid::Snowflake, ::AbstractPlugin)
Says whether the plugin is enabled on a given server
"""
function isenabled end

end
