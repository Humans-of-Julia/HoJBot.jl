function game_master_commander(c::Client, m::Message)
    @info "game_master_commander called"
    startswith(m.content, COMMAND_PREFIX * "gm") || return

    regex = Regex(COMMAND_PREFIX * raw"gm( help| in| out)? *(.*)$")

    matches = match(regex, m.content)

    if matches === nothing || matches.captures[1] ∈ (" help", nothing)
        help_game_master_commander(c, m)
    elseif matches.captures[1] == " in"
        @info "opt-in was required" m.content m.author.username m.author.discriminator

    elseif matches.captures[1] == " out"
        @info "opt-out was required" m.content m.author.username m.author.discriminator
    else
        reply(c, m, "Sorry, are you playing me? Please check out `gm help`")
    end
    return nothing
end

function help_game_master_commander(c::Client, m::Message)
    reply(c, m, """
        How to play with the `gm` command:
        ```
        gm help
        gm in
        gm out
        ```
        The commands `in` and `out` are to opt-in and opt-out of the game. Playing data of an `out` player are kept until the end of the game. An `out` player can come `in` anytime to resume its participation!
        """)
end

function opt_in(c::Client, m::Message)
    reply(c, m,
        """
        The `opt_in` function is being implemented. Please try again once it is released.
        """
    )
end

function opt_out(c::Client, m::Message)
    reply(c, m,
        """
        The `opt_in` function is being implemented. Please try again once it is released.
        """
    )
end
