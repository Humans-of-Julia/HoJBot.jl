function game_master_commander(c::Client, m::Message)
    @info "game_master_commander called"
    startswith(m.content, COMMAND_PREFIX * "gm") || return

    regex = Regex(COMMAND_PREFIX * raw"gm( help| opt-in| opt-out)? *(.*)$")

    matches = match(regex, m.content)

    if matches === nothing || matches.captures[1] ∈ (" help", nothing)
        help_game_master_commander(c, m)
    elseif matches.captures[1] == "opt-in"
        @info "Opt-in was required" m.content m.author.username m.author.discriminator
    elseif matches.captures[1] == "opt-out"
        @info "Opt-out was required" m.content m.author.username m.author.discriminator
    else
        reply(c, m, "Sorry, are you playing me? Please check out `gm help`")
    end
    return nothing
end
