module HoJBot

export start_bot

using Discord
using Dates
using TimeZones

const COMMAND_PREFIX = ","

include("main.jl")
include("command/tz.jl")
include("command/j.jl")
include("command/src.jl")
include("handler/reaction.jl")

end # module
