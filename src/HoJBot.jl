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

function loadplugins()
    includejlfiles("type/")
    includejlfiles("command/")
    includejlfiles("handler/")
end

function includejlfiles(dir)
    wd = walkdir(dir)
    commands = first(wd)
    close(wd)
    foreach(commands[3]) do command
        endswith(command, ".jl") && include(joinpath(commands[1], command))
    end
end

include("constants.jl")
include("dispatcher.jl")
include("util.jl")
include("discord.jl")
include("main.jl")

loadplugins()

end # module
