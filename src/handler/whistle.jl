# Whistle blower - complain about inappropriate content

"""
Number of whistle blower reports for a message.
- Key: `message_id`
- Value: count of whistle blower reports
"""
const WHISTLE_REPORTS_COUNT = Dict{UInt64,UInt64}()

"""
Which messages a whistle blower has reported so far.
- Key: `user_id`
- Value: Set of `message_id`
"""
const WHISTLE_REPORTS = Dict{UInt64,Set{UInt64}}()

"""
How many reports needs to be received before the message is deleted.
"""
const WHISTLE_MIN_REPORTS_FOR_REMOVAL = 3

"""
Emoji used to trigger a whistle blower report
"""
const WHISTLE_EMOJI = "🚷"

const WHISTLE_BLOWER_THANK_YOU_MESSAGE = replace_newlines("""
    **Thank you for the report.** :thumbsup:
    The message with potentially inappropriate content will be
    removed automatically once we receive enough reports.
    Please direct any question to the Moderator team.
    Your reaction emoji has also been instantly removed from
    the original message in order to keep your report anonymous
    from the public.
    """)

"""
    handler(c::Client, e::MessageReactionAdd, ::Val{:whistle})

Handle whistle blower reports. The complete flow is as follows:

1. Reporter places a special emoji on the potentially inappropriate message
2. This handler function is called.
3. Increment the counter for whistle blower reports on the reported message
4. If there are enough reports, delete the reported message
5. Otherwise, just remove the emoji.
6. Send a DM to the report about the action that's taken.
7. Log an audit event.
"""
function handler(c::Client, e::MessageReactionAdd, ::Val{:whistle})

    if e.emoji.name === WHISTLE_EMOJI
        @info "MessageReactionAdd (whistle)" e.user_id e.channel_id e.message_id e.emoji

        # Find previous reports by this user
        prior_user_reports = get!(WHISTLE_REPORTS, e.user_id, Set{UInt64}())

        # Increment counter
        count = get!(WHISTLE_REPORTS_COUNT, e.message_id, 0)
        if e.message_id ∉ prior_user_reports  # do not over-count
            count += 1
        end
        WHISTLE_REPORTS_COUNT[e.message_id] = count

        if count >= WHISTLE_MIN_REPORTS_FOR_REMOVAL
            @info "Max reports reached" e.user_id e.channel_id e.message_id
            # delete the message
            m = Message(; id = e.message_id, channel_id = e.channel_id)
            @discord delete(c, m)
        else
            # remove the emoji to protect reporter's identity
            m = Message(; id = e.message_id, channel_id = e.channel_id)
            u = User(; id = e.user_id)
            @discord delete(c, e.emoji, m, u)
        end

        # thank reporter
        dm_channel = fetchval(create_dm(c; recipient_id = e.user_id))
        uuid = string(uuid4())[end-11:end]
        reference = " (Reference ID: $uuid)"
        @discord create(c, Message, dm_channel;
            content = WHISTLE_BLOWER_THANK_YOU_MESSAGE * reference)

        # remember this report
        push!(prior_user_reports, e.message_id)

        # log an audit event
        user = @discord retrieve(c, User, e.user_id)
        audit("whistle",
            user.id, user.username, user.discriminator,
            "message_id=$(e.message_id) uuid=$uuid count=$count")
    end
end
