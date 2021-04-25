# Discord delegate functions so that the bot can be tested more easily with the Pretend framework.

@mockable function discord_channel(c::Client, channel_id::UInt64)
    return @discord retrieve(c, DiscordChannel, channel_id)
end

@mockable function discord_upload_file(c::Client, channel::DiscordChannel, filename::AbstractString; kwargs...)
    return @discord upload_file(c, channel, filename; kwargs...)
end

@mockable function discord_reply(c::Client, m::Message, content::AbstractString)
    return @discord reply(c, m, content)
end
