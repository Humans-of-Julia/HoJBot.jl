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

import HTTP
import JSON3
import StructTypes

const COMMAND_PREFIX = get(ENV, "HOJBOT_COMMAND_PREFIX", ",")

include("dispatcher.jl")
include("util.jl")
include("discord.jl")
include("main.jl")

include("command/tz.jl")
include("command/j.jl")
include("command/gm.jl")
include("command/react.jl")

include("handler/reaction.jl")
include("handler/whistle.jl")

include("type/discourse.jl")
include("command/discourse.jl")
include("handler/discourse.jl")

include("type/ig.jl")
include("command/ig.jl")

end # module
