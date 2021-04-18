function commander(c::Client, m::Message, ::Val{:discourse})
    @info "discourse_commander called"
    startswith(m.content, COMMAND_PREFIX * "discourse") || return

    regex = Regex(COMMAND_PREFIX * raw"discourse( .*)$")
    matches = match(regex, m.content)
    if matches === nothing
        help_commander(c, m, :discourse)
        return
    end
    arg = strip(matches.captures[1])
    if arg == "latest"
        endpoint = "posts.json"
        params = Dict{Symbol,String}()
        topic_fn = x -> x.latest_posts
        make_post_fn = x -> DiscoursePost(x.topic_id, x.topic_slug)
    elseif arg == "top"
        endpoint = "top/weekly.json"
        params = Dict{Symbol,String}()
        topic_fn = x -> x.topic_list.topics
        make_post_fn = x -> DiscoursePost(x.id, x.slug)
    else
        endpoint = "search.json"
        params = Dict(:q => arg)
        topic_fn = x -> x.topics
        make_post_fn = x -> DiscoursePost(x.id, x.slug)
    end
    discourse_search(c, m, endpoint, params, topic_fn, make_post_fn)
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:discourse})
    reply(c, m, """
        Perform a search on Julia Discourse.
        ```
        discourse <query>
        discourse top
        discourse latest
        ```
        """)
end

"""
    discourse_search(
        c::Client,
        m::Message,
        endpoint::AbstractString,
        params::Dict{Symbol, S},
        topic_fn::Function,
        make_post_fn::Function
    ) where {S <: AbstractString}

Perform a search on Julia Discourse with the provided `endpoint`
and query parameters `params`. Use `topic_fn` to index into the
JSON array and `make_post_fn` to construct a `DiscoursePost`
object for each hit.

Create a Discord message with the result and save the data.
"""
function discourse_search(
    c::Client,
    m::Message,
    endpoint::AbstractString,
    params::Dict{Symbol, S},
    topic_fn::Function,
    make_post_fn::Function
) where {S <: AbstractString}
    data = discourse_execute_query(endpoint, params, topic_fn, make_post_fn)
    new_message = reply(c, m, data)
    discourse_save(new_message.id, data)
end

"""
    discourse_execute_query(
        endpoint::AbstractString,
        params::Dict{Symbol, AbstractString},
        topic_fn::Function,
        make_post_fn::Function
    )

Execute a query and return `DiscourseData` object.
"""
function discourse_execute_query(
    endpoint::AbstractString,
    params::Dict{Symbol, S},
    topic_fn::Function,
    make_post_fn::Function
) where {S <: AbstractString}
    json = discourse_run_query(endpoint, params)
    return DiscourseData(topic_fn(json), make_post_fn)
end

"""
    discourse_run_query(endpoint::AbstractString, params::Dict{Symbol, AbstractString})

Run Discourse query and return result as a JSON3 object.
"""
function discourse_run_query(endpoint::AbstractString, params::Dict{Symbol, S}) where {
    S <: AbstractString
}
    sanitized_kv = Dict(HTTP.escapeuri(k) => HTTP.escapeuri(v) for (k,v) in params)
    params_str = join(["$k=$v" for (k,v) in sanitized_kv], "&")
    response = HTTP.get(
        "$DISCOURSE_DOMAIN/$endpoint?$params_str",
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
