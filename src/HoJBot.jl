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

include("type/mod.jl")

include("type/discourse.jl")

include("type/ig.jl")

loadcommands()

loadhandlers()

function loadcommands()
    wd = walkdir("command/")
    commands = first(wd)
    close(wd)
    foreach(commands[3]) do command
        include(joinpath(commands[1], command))
    end
end

function loadhandler()
    wd = walkdir("handler/")
    handlers = first(wd)
    close(wd)
    foreach(handlers[3]) do handler
        include(joinpath(handlers[1], handler))
    end
end

end # module
