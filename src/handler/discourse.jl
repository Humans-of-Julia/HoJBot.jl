function handler(c::Client, e::MessageReactionAdd, ::Val{:discourse})
    user = @discord retrieve(c, User, e.user_id)
    @info "discourse handler" user.username user.discriminator user.bot

    if e.emoji.name === "👈" && is_real_user(user)
        flip(c, e, flipper(previous, DiscourseData))
    elseif e.emoji.name === "👉" && is_real_user(user)
        flip(c, e, flipper(next, DiscourseData))
    else
        return  # no more action required
    end

    # unwind reaction
    delete_emoji(c, e.channel_id, e.message_id, e.user_id, e.emoji)
end

function flip(c::Client, e::MessageReactionAdd, flip::TypedFunction{DiscourseData})
    data = discourse_load(e.message_id)
    new_data = flip(data)
    discourse_save(e.message_id, new_data)
    update_message(c, e.channel_id, e.message_id, message(new_data))
end
