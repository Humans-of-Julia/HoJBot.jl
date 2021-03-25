# implement julia_commander
# for the moment, only help on an object is implemented

function julia_commander(c::Client, m::Message)
    # @info "julia_commander called"
    # @info "Message content" m.content m.author.username m.author.discriminator
    startswith(m.content, COMMAND_PREFIX * "j") || return
    regex = Regex(COMMAND_PREFIX * raw"j(\?| help)? *(.*)$")
    matches = match(regex, m.content)
    if matches === nothing || 
        ((matches.captures[1] in ("?", " help", nothing)) & (matches.captures[2] == ""))
        help_julia_commander(c, m)
    elseif matches.captures[1] in ("?", " help")
        handle_julia_help_commander(c, m, matches.captures[2])
    else
        reply(c, m, "Sorry, I don't understand the request; use `j?` or `j help` for help")
    end
    return nothing
end

function help_julia_commander(c::Client, m::Message)
    # @info "Sending help for message" m.id m.author
    reply(c, m, """
        For the moment, only "help" is accept, with the aim of showing the docstring for a julia object.

        How to use the `j` command:
        ```
        j?
        j help
        j? <object>
        j help <object>
        ```
        `j?` and `j help` return this help
        `j? <object>` and `j <object>` return the documentation for the object
        """)
    return nothing
end

function handle_julia_help_commander(c::Client, m::Message, s::AbstractString)
    # @info "julia_help_commander called"
    if any((' ', '(', ')') .∈ s)
        reply(c, m, "Sorry, no space or parenthesis allowed in the help query")
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

