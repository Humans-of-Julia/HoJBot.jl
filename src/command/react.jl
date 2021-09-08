function commander(c::Client, m::Message, ::Val{:reaction})
    @info "reaction_commander called"
    startswith(m.content, COMMAND_PREFIX * "react") || return nothing

    regex = Regex(COMMAND_PREFIX * raw"react( help| in| out)? *(.*)$")

    matches = match(regex, m.content)

    if matches === nothing || matches.captures[1] ∈ (" help", nothing)
        help_commander(c, m, :reaction)
    elseif matches.captures[1] == " in"
        @info "opt-in was required" m.content m.author.username m.author.discriminator
        opt_in(c, m, :reaction)
    elseif matches.captures[1] == " out"
        @info "opt-out was required" m.content m.author.username m.author.discriminator
        opt_out(c, m, :reaction)
    else
        reply(c, m, "Sorry, are you playing me? Please check`react help`")
    end
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:reaction})
    return reply(
        c,
        m,
        """
        How to opt-in/out of the `reaction` bot:
        ```
        react help
        react in
        react out
        ```
        The commands `in` and `out` are to opt-in and opt-out of the reaction bot.
        """,
    )
end
