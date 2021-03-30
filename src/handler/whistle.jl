# Whistle blower - complain about inappropriate content

struct WhistleBlower
    user_id::UInt64
    message_id::UInt64
end

# In-memory cache that keeps track of how many whistle blower reports
# for the message.
#   Key: message_id
#   Value: count of whistle blower reports
const WHISTLE_REPORTS_COUNT = Dict{UInt64,UInt64}()

# Keep track of how which messages a whistle blower has reported
#   Key: user_id
#   Value: Set of message_id
const WHISTLE_REPORTS = Dict{UInt64,Set{UInt64}}()

# How many reports needs to be received before the message should
# be deleted.
const REMOVE_MESSAGE_MIN_REPORTS = 3

# Emoji used to trigger a whistle blower report
const WHISTLE_EMOJI = "🚷"

const WHISTLE_BLOWER_THANK_YOU_MESSAGE = remove_newline("""
    Thank you for your whistle blower report. The message with potentially
    inappropriate content will be removed automatically once we receive
    enough reports. Please direct any questions to the @Moderator team.
    """)

# Handler
function handler(c::Client, e::MessageReactionAdd, ::Val{:whistle})
    @info "MessageReactionAdd" e.user_id e.channel_id e.message_id e.emoji

    # Find previous reports by this user
    prior_user_reports = get!(WHISTLE_REPORTS, e.user_id, Set{UInt64}())

    # If emoji matches
    if e.emoji.name === WHISTLE_EMOJI

        # Increment counter
        count = get!(WHISTLE_REPORTS_COUNT, e.message_id, 0)
        if e.message_id ∉ prior_user_reports  # do not over-count
            count += 1
        end
        WHISTLE_REPORTS_COUNT[e.message_id] = count

        if count >= REMOVE_MESSAGE_MIN_REPORTS
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
            content = WHISTLE_BLOWER_THANK_YOU_MESSAGE)

        # remember this report
        push!(prior_user_reports, e.message_id)

        # log an audit event
        user = @discord retrieve(c, User, e.user_id)
        audit(user.id, user.username, user.discriminator,
            "whistle report against message $(e.message_id) ref=$uuid cnt=$count")
    end
end
