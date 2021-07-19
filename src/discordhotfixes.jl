function Discord.reply(c::Client, m::Message, content::AbstractString; at::Bool=false)
    at && !ismissing(m.author) && (content = string(m.author, " ", content))
    return create_message(c, m.channel_id; content=content, message_reference=(;message_id=m.id))
end

function Discord.reply(
    c::Client,
    m::Message,
    embed::Union{AbstractDict, NamedTuple, Embed};
    at::Bool=false,
)
    return if at && !ismissing(m.author)
        create_message(c, m.channel_id; content=string(m.author), embed=embed, message_reference=(;message_id=m.id))
    else
        create_message(c, m.channel_id; embed=embed, message_reference=(;message_id=m.id))
    end
end
