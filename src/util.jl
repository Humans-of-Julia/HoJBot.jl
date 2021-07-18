"""
    replace_newlines(s::AbstractString, replacement = " ")

Replace newlines with something other string. This is useful when you want to
"wrap" multiple lines into a single line. Hence the default replacement is just
a blank space.
"""
function replace_newlines(s::AbstractString, replacement = " ")
    return replace(s, r"\n" => replacement)
end

"""
    @discord(ex)

Evaluate any Discord.jl function that is expected to return a future.
The response is captured and logged at Debug level before the
underlying value is returned.
"""
macro discord(ex)
    return quote
        future = $(esc(ex))
        response = fetch(future)
        @debug "Response received" response
        response.val
    end
end

# Convenient Discord functions

"""
    delete_emoji(c::Client, channel_id::UInt64, message_id::UInt64, user_id::UInt64, emoji::Emoji)

Delete the specified user's emoji from a Discord message.
"""
function delete_emoji(c::Client, channel_id::UInt64, message_id::UInt64, user_id::UInt64, emoji::Emoji)
    message = Message(; id = message_id, channel_id = channel_id)
    user = User(; id = user_id)
    return @discord delete(c, emoji, message, user)
end

"""
    update_message(c::Client, channel_id::UInt64, message_id::UInt64, content::AbstractString)

Update a Discord message with new content.
"""
function update_message(c::Client, channel_id::UInt64, message_id::UInt64, content::AbstractString)
    message = Message(; id = message_id, channel_id = channel_id)
    return @discord update(c, message; content)
end

"""
    is_real_user(u::User)

Returns true if the user is not a bot.
"""
is_real_user(u::User) = ismissing(u.bot) || u.bot === false

"""
    is_bot(u::User)

Returns true if the user is a bot.
"""
is_bot(u::User) = !is_real_user(u)

# Generic flipping functions

"""
    previous

Flip state to the previous item. If it passes the beginning of the list,
reset the state to the last item.
"""
function previous end

"""
    next

Flip state to the next item. If it passes the end of the list,
reset the state to the first item.
"""
function next end

"""
    flipper(f::Union{typeof(previous), typeof(next)}, T::Type)

Return a flip function, either `previous` or `next`, that expects
argument of type `T`.
"""
flipper(f::Union{typeof(previous), typeof(next)}, T::Type) = TypedFunction{T}(f)

"""
    extract_command(command::AbstractString, s::AbstractString)

Extract command by removing the command prefix. For example:

```
julia> HoJBot.extract_command("j", ",j doc sin")
"doc sin"
```
"""
function extract_command(command::AbstractString, s::AbstractString)
    prefix = COMMAND_PREFIX * command
    return strip(replace(s, Regex("^" * prefix * " *") => ""))
end

"""
    ensurepath!(fileorpath::AbstractString)

Ensure that the path exists in a way that writing to path does not error.
Returns the argument afterwards for composability.
"""
function ensurepath!(fileorpath::AbstractString)
    mkpath(dirname(fileorpath))
    return fileorpath
end

# TODO move to constants.jl later
const Optional{T} = Union{T, Nothing}
