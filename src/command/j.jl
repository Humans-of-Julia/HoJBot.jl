function julia_help_commander(c::Client, m::Message)
    # @info "julia_help_commander called"
    # @info "Message content" m.content m.author.username m.author.discriminator
    startswith(m.content, COMMAND_PREFIX * "j") || return
    regex = Regex(COMMAND_PREFIX * raw"j(\?| help)? *(.*)$")
    matches = match(regex, m.content)
    if matches === nothing || 
        ((matches.captures[1] in ("?", " help")) & (matches.captures[2] == ""))
        help_julia_help_commander(c, m)
    elseif matches.captures[1] in ("?", " help")
        handle_julia_help_commander(c, m, matches.captures[2])
    else
        reply(c, m, "Sorry, I don't understand the request; use `j?` or `j help` for help")
    end
    return nothing
end

function help_julia_help_commander(c::Client, m::Message)
    # @info "Sending help for message" m.id m.author
    reply(c, m, """
        How to use the `j` command:
        ```
        j?
        j help
        j? <object>
        j help <object>
        ```
        where `j?` and `j help` return this help and `j? <object>` 
        and `jh <object>` return the documentation
        for the given julia object.
        """)
    return nothing
end

function handle_julia_help_commander(c::Client, m::Message, s::AbstractString)
    @info "julia_help_commander called"
    if any((' ', '(', ')') .∈ s)
        reply(c, m, "Sorry, no space or parenthesis allowed in query")
    else
        try
            obj = split(s,r" |\)")[1]
            doc = eval(Meta.parse("Docs.@doc("*obj*")"))
            reply(c, m, """
                $doc
                """)
        catch ex
            @show ex
            reply(c, m, "Sorry, I don't understand the request")
        end
    end
    return nothing
end

