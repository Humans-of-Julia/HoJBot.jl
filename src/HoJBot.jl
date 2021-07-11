module HoJBot

export start_bot

using Discord: Snowflake

include("pluginbase.jl")

import .PluginBase: handle_command as commander, handle_observer as handler

const COMMAND_PREFIX = get(ENV, "HOJBOT_COMMAND_PREFIX", ",")

include("dispatcher.jl")
include("util.jl")
include("discord.jl")
include("main.jl")
# include("rights.jl")

include("plugins/storage.jl")
include("plugins/filebackend.jl")
include("plugins/permission.jl")
include("plugins/queue.jl")

end # module
