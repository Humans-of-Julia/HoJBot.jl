module HoJBot

export start_bot

using CSV
using DataFrames
using Dates
using Discord
using Downloads
using ExpiringCaches
using Formatting
using JSON
using OrderedCollections
using Plots
using Pretend
using PrettyTables
using TimeZones
using UUIDs
using Pkg

import HTTP
import JSON3
import StructTypes

const COMMAND_PREFIX = get(ENV, "HOJBOT_COMMAND_PREFIX", ",")

include("constants.jl")
include("dispatcher.jl")
include("util.jl")
include("discord.jl")
include("main.jl")

include("command/tz.jl")
include("command/j.jl")
include("command/gm.jl")
include("command/react.jl")
include("command/src.jl")

include("handler/reaction.jl")
include("handler/whistle.jl")

include("type/mod.jl")
include("handler/mod.jl")

include("type/discourse.jl")
include("command/discourse.jl")
include("handler/discourse.jl")

include("type/ig.jl")
include("command/ig.jl")

end # module
