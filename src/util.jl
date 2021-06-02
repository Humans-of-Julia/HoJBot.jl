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

"""
    audit(source, user_id, name, discriminator, message; audit_dir, audit_file)

Create an audit record in the system for a given event.

# Arguments
- `source`: unique string representing where the audit log comes from
- `user_id`: Discord user id
- `name`: Discord user name
- `discriminator`: Discord user discriminator
- `audit_dir`: audit log directory, defaults to `data/audit`
- `audit_file`: audit log file, defaults to `\$audit_dir/\$source.log`
"""
function audit(
    source::AbstractString,
    user_id::UInt64,
    name::AbstractString,
    discriminator::AbstractString,
    message::AbstractString;
    audit_dir = joinpath("data", "audit"),
    audit_file = joinpath(audit_dir, "$source.log")
)
    mkpath(audit_dir)
    open(joinpath(audit_file); write = true, append = true) do io
        println(io, "$(now(tz"UTC"))\t$name#$discriminator\t$user_id\t$message")
    end
end

"""
    load_docs(filename)::Dict{String, Dict{String, String}}

Return a Dict with the packages (keys) and name => docstring pairs (values)
of all available packages in the given JSON file.
"""
function load_docs(filename)::Dict{String, Dict{String, String}}
    all_docs = JSON.parsefile(filename)
    all_docs = convert(Dict{String, Dict{String, String}}, all_docs)
    return all_docs
end

"""
    load_names(filename::String)::Nothing

Save to a JSON file the list of names and the associated list of corresponding
packages each name appears in.
"""
function load_names(filename::String)::Dict{String,Vector{String}}
    all_names = JSON.parsefile(filename)
    all_names = convert(Dict{String,Vector{String}}, all_names)
    return all_names
end

function update_names_count(
        source::AbstractString,
        name::AbstractString,
        channel_id::UInt64,
        channel_name::AbstractString,
        count_docs_dir = joinpath("data", "docs"),
        count_names_file = joinpath(count_docs_dir, "$source.json")
    )
    
    mkpath(count_docs_dir)
    isfile(count_names_file) || write(count_names_file, "{}")
    namescount = JSON.parsefile(count_names_file)

    info = [
        Dict(
            "when" => """$(now(tz"UTC"))""",
            "channel" => "$channel_name",
            "channel_id" => "$channel_id"
        )
    ]

    if name in keys(namescount)
        namescount[name]["count"] += 1
        append!(
            namescount[name]["info"], info
        )
    else
        push!(
            namescount, 
                name => Dict(
                    "count" => 1,
                    "info" => info
                )
        )
    end
    write(count_names_file, JSON.json(namescount, 4))
    return namescount[name]["count"]
end

function stats_namescount(
        source::AbstractString;
        place::AbstractString = "top",
        number::Int = 20,
        name::AbstractString = "",
        count_docs_dir = joinpath("data", "docs"),
        count_names_file = joinpath(count_docs_dir, "$source.json")
    )

    isfile(count_names_file) || return "Sorry, no stats found."
    namescount = JSON.parsefile(count_names_file)
    name = strip(name)
    if length(name) > 0
        if name in keys(namescount)
            return "The docstring for `$name` has been looked upon $(namescount[name]["count"]) times!"
        else
            return "The docstring for `$name` has not been looked upon yet."
        end
    end
    rev = place == "top" ? true : false
    stats = sort(collect(namescount), by=x->x[2]["count"], rev=rev)[1:min(end, number, 100)]
    header = ifelse(place == "top", "**Top ", "**Bottom ") * "$(min(length(stats), number, 100)) stats**\n"
    header *= "≡"^(length(header)-8) * "\n__Count__\t__Name__\n"
    contents = prod(map(s -> "$(s[2]["count"])\t\t\t`$(s[1])`\n", stats))
    return header * contents
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
    @discord update(c, message; content)
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

# TODO move to constants.jl later
const Optional{T} = Union{T, Nothing}
