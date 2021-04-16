module HoJBot

export start_bot

using Discord
using Dates
using JSON
using OrderedCollections
using TimeZones
using UUIDs

import HTTP
import JSON3
import StructTypes

const COMMAND_PREFIX = get(ENV, "HOJBOT_COMMAND_PREFIX", ",")

include("dispatcher.jl")
include("util.jl")
include("main.jl")

include("command/tz.jl")
include("command/j.jl")
include("handler/reaction.jl")
include("handler/whistle.jl")

include("type/discourse.jl")
include("command/discourse.jl")
include("handler/discourse.jl")

end # module
