module HoJBot

export start_bot

using Discord
using Dates
using JSON
using OrderedCollections
using TimeZones

const COMMAND_PREFIX = get(ENV, "HOJBOT_COMMAND_PREFIX", ",")

include("main.jl")
include("command/tz.jl")
include("command/j.jl")
include("command/gm.jl")
include("command/react.jl")
include("handler/reaction.jl")

end # module
