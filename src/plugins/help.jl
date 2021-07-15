module Help

using Discord
using Discord: Snowflake
using ..PluginBase

struct HelpPlugin <: AbstractPlugin end

const PLUGIN = HelpPlugin()

function __init__()
    register!(PLUGIN)
end

function PluginBase.initialize(client::Client, ::HelpPlugin)
    add_command!(client, :help, (c, m) -> handle_command(c, m, PLUGIN))
end

function PluginBase.handle_command

function PluginBase.help()

end

function gethelp(args...)
    
end

end
