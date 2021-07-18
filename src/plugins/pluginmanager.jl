module PluginManager

using ..PluginBase
using Discord
using Discord: Snowflake

struct PluginManagerPlugin <: AbstractPlugin end

const PLUGIN = PluginManagerPlugin()

struct PluginManagerPermission <: AbstractPermission end

const PERM = PluginManagerPermission()

PluginBase.isenabled(guid::Snowflake, ::PluginManagerPlugin) = true

function __init__()
    register!(PLUGIN)
end

function PluginBase.initialize!(client::Client, ::PluginManagerPlugin)
    add_command!(client, :plugin, (c, m) -> handle(c, m))
    return true
end

function handle(c::Client, m::Message)
    isenabled(m.guild_id, m.channel_id, PLUGIN) || return
    is_permitted(c, m, PERM) || return
    args = split(m.content)
    length(args) < 3 && reply(c, m, "Unknown command")
    subcommand = args[2]
    plug = plugin_by_identifier(args[3])
    if plug===nothing
        reply(c, m, "$(args[3]) is an invalid plugin identifier")
    elseif subcommand == "enable!"
        reply(c, m, enable!(m.guild_id, plug))
    elseif subcommand == "disable!"
        reply(c, m, disable!(m.guild_id, plug))
    elseif subcommand == "lockout!"
        reply(c, m, lockout!(m.guild_id, m.channel_id, plug))
    elseif subcommand == "letin!"
        reply(c, m, letin!(m.guild_id, m.channel_id, plug))
    end
end

function enable!(guid::Snowflake, p::AbstractPlugin)
    enabled = get_storage(guid, PLUGIN)
    listed = get(enabled, p, nothing)
    listed === nothing || return "already enabled"
    enabled[p] = Snowflake[]
    return "enabled plugin $(identifier(p))"
end

function disable!(guid::Snowflake, p::AbstractPlugin)
    enabled = get_storage(guid, PLUGIN)
    listed = get(enabled, p, nothing)
    listed !== nothing || return "already disabled"
    delete!(enabled, p)
    return "disabled plugin $(identifier(p))"
end

function lockout!(guid::Snowflake, channel::Snowflake, p::AbstractPlugin)
    enabled = get_storage(guid, PLUGIN)
    listed = get(enabled, p, nothing)
    listed !== nothing || return "plugin is not enabled"
    push!(listed, channel)
    return "locked $(identifier(p)) out of this channel"
end

function letin!(guid::Snowflake, channel::Snowflake, p::AbstractPlugin)
    enabled = get_storage(guid, PLUGIN)
    listed = get(enabled, p, nothing)
    listed !== nothing || return "plugin is not enabled"
    delete!(listed, channel)
    return "allowed $(identifier(p)) into this channel"
end

#plugin enable! <plugin> -> server wide enable

#plugin disable! <plugin> -> server wide disable

#plugin lockout! <plugin> -> disable the plugin in the channel of the command

#plugin letin! <plugin> -> enable the plugin in the channel of the command

function PluginBase.isenabled(guid::Snowflake, channel::Snowflake, to_test::AbstractPlugin)
    enabled = get_storage(guid, PLUGIN)
    listed = get(enabled, to_test, nothing)
    return listed===nothing ? isenabled(guid, to_test) : !(channel in listed)
end

PluginBase.isenabled(guid::Snowflake, to_test::AbstractPlugin) = false

function PluginBase.create_storage(backend::AbstractPlugin, ::PluginManagerPlugin)
    return Dict{AbstractPlugin, Set{Snowflake}}()
end

end
