function handler(c::Client, e::MessageReactionAdd, ::Val{:discourse})

    # Only handle this event when message corresponds to a previous
    # Discourse query.
    isfile(discourse_file_path(e.message_id)) || return nothing

    user = @discord retrieve(c, User, e.user_id)
    @info "discourse handler" user.username user.discriminator user.bot

    if e.emoji.name === "👈" && is_real_user(user)
        flip(c, e, flipper(previous, DiscourseData))
    elseif e.emoji.name === "👉" && is_real_user(user)
        flip(c, e, flipper(next, DiscourseData))
    else
        return nothing  # no more action required
    end

    # unwind reaction
    delete_emoji(c, e.channel_id, e.message_id, e.user_id, e.emoji)
    return nothing
end

function flip(c::Client, e::MessageReactionAdd, flip::TypedFunction{DiscourseData})
    data = discourse_load(e.message_id)
    new_data = flip(data)
    discourse_save(e.message_id, new_data)
    update_message(c, e.channel_id, e.message_id, message(new_data))
    return nothing
end
