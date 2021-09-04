const FILTERED_ACTIVE_CMDS = keys((filter(check -> last(check) == true, ACTIVE_COMMANDS)))

function commander(c::Client, m::Message, ::Val{:source})
    startswith(m.content, COMMAND_PREFIX * "src") || return nothing

    regex = Regex(COMMAND_PREFIX * raw"src( help| [a-zA-Z]*)? *(.*)$")

    matches = match(regex, m.content)

    if matches === nothing || matches.captures[1] ∈ (" help", nothing)
        help_commander(c, m, :source)
    else
        command = lowercase(strip(matches.captures[1]))
        if Symbol(command) ∈ FILTERED_ACTIVE_CMDS
            msg = string(BOT_REPO_URL, "/blob/main/src/command/", command, ".jl")
            reply(c, m, msg)
        else
            reply(c, m, "No such blob or file. Please check out $(BOT_REPO_URL) instead")
        end
    end
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:source})
    list_commands = join(
        sort([string("src", " ", cmd, "\n") for cmd in FILTERED_ACTIVE_CMDS])
    )

    return reply(
        c,
        m,
        """
        Returns the source file of the command.
        Usage: `src <command>`
        List of available commands:
        ```
        $(list_commands)
        ```
        `src` or `src help` returns help
        """,
    )
end
