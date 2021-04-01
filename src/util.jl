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
