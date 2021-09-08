function commander(c::Client, m::Message, ::Val{:game_master})
    startswith(m.content, COMMAND_PREFIX * "gm") || return nothing

    regex = Regex(COMMAND_PREFIX * raw"gm( help| in| out)? *(.*)$")

    matches = match(regex, m.content)

    if matches === nothing || matches.captures[1] ∈ (" help", nothing)
        help_commander(c, m, :game_master)
    elseif matches.captures[1] == " in"
        @info "opt-in was required" m.content m.author.username m.author.discriminator
        opt_in(c, m, :game_master)
    elseif matches.captures[1] == " out"
        @info "opt-out was required" m.content m.author.username m.author.discriminator
        opt_out(c, m, :game_master)
    else
        reply(c, m, "Sorry, are you playing me? Please check out `gm help`")
    end
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:game_master})
    return reply(
        c,
        m,
        """
        How to play with the `gm` command:
        ```
        gm help
        gm in
        gm out
        ```
        The commands `in` and `out` are to opt-in and opt-out of the game. Playing data of an `out` player are kept until the end of the game. An `out` player can come `in` anytime to resume its participation!
        """,
    )
end
