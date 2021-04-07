module HoJBot

export start_bot

using Discord
using Dates
using JSON
using OrderedCollections
using TimeZones
using UUIDs
using Pkg

const COMMAND_PREFIX = get(ENV, "HOJBOT_COMMAND_PREFIX", ",")

include("util.jl")
include("main.jl")
include("command/tz.jl")
include("command/j.jl")
include("command/gm.jl")
include("command/react.jl")
include("handler/reaction.jl")
include("handler/whistle.jl")

end # module
