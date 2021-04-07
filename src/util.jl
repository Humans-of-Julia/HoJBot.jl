function remove_newline(s::AbstractString)
    return replace(s, r"\n" => " ")
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

function update_namescount(
        source::AbstractString,
        name::AbstractString,
        user_id::UInt,
        username::AbstractString,
        discriminator::AbstractString,
        channel_id::UInt,
        channel_name::AbstractString,
        count_docs_dir = joinpath("data", "docs"),
        count_names_file = joinpath(count_docs_dir, "$source.json")
    )
    
    mkpath(count_docs_dir)
    isfile(count_names_file) || write(count_names_file, "{}")
    namescount = JSON.parsefile(count_names_file)

    info = [
        Dict(
            "who" => "$username#$discriminator(id:$user_id)",
            "when" => "$(now(tz"UTC"))",
            "where" => "#$channel_name(id:$channel_id)"
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
    if length(name) > 0
        if name in keys(namescount)
            return "The docstring for `$name` has been looked upon $(namescount[name]["count"]) times!"
        else
            return "The docstring for `$name` has not been looked upon yet."
        end
    end
    stats = sort(collect(namescount), by=x->x[2]["count"], rev=true)[1:min(end,number, 100)]
    header = ifelse(place == "top", "**Top ", "**Bottom ")*"$(min(length(stats),number, 100)) stats**\n"
    header *= "≡"^(length(header)-8)*"\n__Count__\t__Name__\n"
    contents = prod(map(s -> "$(s[2]["count"])\t\t\t`$(s[1])`\n", stats))
    return header*contents
end
