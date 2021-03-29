function commander(c::Client, m::Message, ::Val{:global_help})
    startswith(m.content, COMMAND_PREFIX * "help") || return
    regex = Regex(COMMAND_PREFIX * raw"help *(.*)$")
    matches = match(regex, m.content)

    if matches === nothing || matches.captures[1] ∈ (" help", nothing)
        help_commander(c, m, :global_help)
    end
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:global_help})
    commands = map(c -> string(c) * "\n", commands_list)
    opt = map(c -> string(c) * "\n", filter(c -> commands_list[c], opt_services_list))
    reply(c, m,
        """
        HoJBot accepts the following commands:
        ```
        $commands
        ```
        The following services are opt-in. Please check the related help command (`service help` for any `service` below).
        ```
        $opt
        ```
        """
    )
end
