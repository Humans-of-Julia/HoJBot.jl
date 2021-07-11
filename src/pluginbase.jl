module PluginBase

export AbstractPlugin, init, shutdown, handle_command, handle_event, create_storage, get_storage, has_permission, grant!, revoke!

abstract type AbstractPlugin end

"""
    init(::AbstractPlugin, initialized::Set{AbstractPlugin})::Bool

Is called with a list of already initialized plugins and returns whether loading was successful or should be deferred
"""
function init(::AbstractPlugin, ::Set{AbstractPlugin})
    return true
end

"Is called when the server is called to shutdown"
function shutdown end

"Entry point for a new command plugin, only triggers on MessageCreate"
function handle_command end

"Entry point for a new observer plugin, triggers on almost all events related to text chat"
function handle_event end

"""
    create_storage(plugin::AbstractPlugin, backend::AbstractPlugin)

Returns an initialized plugin storage. Defaults to a Symbol->Any Dict

Defined by: each plugin that needs storage in any backend
"""
function create_storage(plugin::AbstractPlugin, backend::AbstractPlugin)
    return Dict{Symbol, Any}()
end

"Request the plugin storage object"
function get_storage end

function has_permission end

function grant! end

function revoke! end

end
