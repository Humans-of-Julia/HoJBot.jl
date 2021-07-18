module HoJBot

export start_bot

using Dates
using Pretend
using Discord
using Discord: Snowflake

include("pluginbase.jl")

const COMMAND_PREFIX = get(ENV, "HOJBOT_COMMAND_PREFIX", ",")

include("dispatcher.jl")
include("util.jl")
include("discord.jl")
include("main.jl")

include("plugins/pluginmanager.jl")
include("plugins/storage.jl")
include("plugins/filebackend.jl")
include("plugins/permission.jl")
# include("plugins/help.jl")
include("plugins/queue.jl")

end # module
