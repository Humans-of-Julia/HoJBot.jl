function commander(c::Client, m::Message, ::Val{:discourse})
    @info "discourse_commander called"
    startswith(m.content, COMMAND_PREFIX * "discourse") || return

    regex = Regex(COMMAND_PREFIX * raw"discourse( .*)$")
    matches = match(regex, m.content)
    if matches === nothing
        help_commander(c, m, :discourse)
        return
    end

    discourse_search(c, m, strip(matches.captures[1]))
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:discourse})
    reply(c, m, """
        Perform a search on Julia Discourse.
        ```
        discourse <query>
        ```
        """)
end

"""
    discourse_search(c::Client, m::Message, query::AbstractString)

Perform a search on Julia Discourse with the provided `query`.
Create a Discord message with the result and save the data.
"""
function discourse_search(c::Client, m::Message, query::AbstractString)
    json = discourse_run_query(query)
    data = DiscourseData(json)
    new_message = reply(c, m, data)
    discourse_save(new_message.id, data)
end

"""
    discourse_run_query(query::AbstractString)

Run Discourse query and return result as a JSON3 object.
"""
function discourse_run_query(query::AbstractString)
    query = HTTP.escapeuri(query)   # sanitize query
    response = HTTP.get(
        "$DISCOURSE_DOMAIN/search.json?q=$query",
        headers = ["Accept" => "application/json"])
    return JSON3.read(response.body)
end

function discourse_save(message_id::UInt64, r::DiscourseData)
    @info "Saving discourse search data for message_id=$message_id"
    path = discourse_file_path(message_id)
    mkpath(dirname(path)) # ensure directory is there
    write(path, JSON3.write(r))
end

function discourse_load(message_id::UInt64)
    @info "Loading discourse search data for message_id=$message_id"
    path = discourse_file_path(message_id)
    bytes = read(path)
    return JSON3.read(bytes, DiscourseData)
end

"Location of the data file"
discourse_file_path(message_id::UInt64) = "data/discourse/$message_id.json"

"""
Reply to user query with a new message containing the current post
from the Discourse search results.
"""
function Discord.reply(c::Client, m::Message, r::DiscourseData)
    @info "Creating result message for message_id=$(m.id)"

    new_message = @discord reply(c, m, message(r))
    @info "New message_id=$(new_message.id)"
    create(c, Reaction, new_message, "👈")
    sleep(0.01) # try to order these emojis properly with a delay
    create(c, Reaction, new_message, "👉")
    return new_message
end
