
function remove_newline(s::AbstractString)
    return replace(s, r"\n" => " ")
end

macro discord(ex)
    return quote
        future = $(esc(ex))
        response = fetch(future)
        @debug "Response received" response
        response.val
    end
end

# A poor-man's way to write audit log
function audit(
    user_id::UInt64,
    name::AbstractString,
    discriminator::AbstractString,
    message::AbstractString;
    audit_dir = "audit",
    audit_file = "audit.log"
)
    isdir(audit_dir) || mkdir(audit_dir)
    open(joinpath(audit_dir, audit_file); write = true, append = true) do io
        println(io, "$(now(tz"UTC")) $name#$discriminator ($user_id) $message")
    end
end
