function game_master_commander(c::Client, m::Message)
    @info "game_master_commander called"
    @info "Message content" m.content m.author.username m.author.discriminator
    startswith(m.content, COMMAND_PREFIX * "gm") || return
    return nothing
end