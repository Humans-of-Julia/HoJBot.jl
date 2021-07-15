module PluginManager

using Discord: Snowflake
using ..PluginBase

struct PluginManagerPlugin <: AbstractPlugin end

const PLUGIN = PluginManagerPlugin()

function __init__()
    register!(PLUGIN)
end

function PluginBase.initialize(client::Client, ::PluginManagerPlugin)
    add_command!(client, :plugin, (c, m) -> handle_command(c, m, PLUGIN))
    return true
end

function PluginBase.isenabled(guid::Snowflake, to_test::AbstractPlugin)
    enabled = get_storage(guid, PLUGIN)
    return to_test in enabled
end

function PluginBase.create_storage(backend::AbstractPlugin, ::PluginManagerPlugin)
    return AbstractPlugin[]
end

function PluginBase.handle_command(c::Client, m::Message, ::PluginManagerPlugin)
    
end

PluginBase.isenabled(guid::Snowflake, ::PluginManagerPlugin) = true

end
