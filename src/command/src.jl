function commander(c::Client, m::Message, ::Val{:source})
    startswith(m.content, COMMAND_PREFIX * "src") || return

    # regex = Regex(COMMAND_PREFIX * raw"src( help| discourse| gm| ig| j| react| src| tz)? *(.*)$")
    regex = Regex(COMMAND_PREFIX * raw"src( help| [a-zA-Z]*)? *(.*)$")

    matches = match(regex, m.content)

    if matches === nothing || matches.captures[1] ∈ (" help", nothing)
        help_commander(c, m, :source)
    else
        command = lowercase(strip(matches.captures[1]))
        real_active_cmds = keys((filter(check -> last(check) == true, active_commands)))
        if Symbol(command) ∈ real_active_cmds
            msg = string(BOT_REPO_URL, "/blob/main/src/command/", command, ".jl")
            reply(c, m, msg)
        else
            reply(c, m, "No such blob or file. Please check out $(BOT_REPO_URL) instead")
        end
    end
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:source})
    return reply(
        c, m, """
     How to use `src` command:
     ```
     src help
     src react
     src <command>
     ```
     Check out the $(BOT_REPO_URL) to see the code and commands.
     """
    )
end
