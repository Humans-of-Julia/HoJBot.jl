# implement julia_commander
# for the moment, only help is implemented

function julia_commander(c::Client, m::Message)
    # @info "julia_commander called"
    # @info "Message content" m.content m.author.username m.author.discriminator
    startswith(m.content, COMMAND_PREFIX * "j") || return
    regex = Regex(COMMAND_PREFIX * raw"j(\?| help| doc)? *(.*)$")
    matches = match(regex, m.content)
    if matches === nothing || matches.captures[1] in (" help", nothing)
        help_julia_commander(c, m)
    elseif matches.captures[1] in ("?", " doc")
        handle_julia_help_commander(c, m, matches.captures[2])
    else
        reply(c, m, "Sorry, I don't understand the request; use `j help` for help")
    end
    return nothing
end

function help_julia_commander(c::Client, m::Message)
    # @info "Sending help for message" m.id m.author
    reply(c, m, """
        For the moment, only "doc" is accept, for showing the docstring.

        How to use the `j` command:
        ```
        j help
        j? <name>
        j doc <name>
        ```
        `j help` returns this help
        `j? <name>` and `j doc <name>` return the documentation for `<name>`
        """)
    return nothing
end

function handle_julia_help_commander(c::Client, m::Message, name::AbstractString)
    # @info "julia_help_commander called"
    if ';' ∈ name
        reply(c, m, "Sorry, no semicolon allowed in the help query")
    else
        try
            doc = string(eval(Meta.parse("Docs.@doc("*name*")")))
            doc = replace(doc, r"\n\n\n+" => "\n\n")
            for m in eachmatch(r"(^|\n)(#+ |!!! )(.*)\n",doc)
                if m.captures[2] == "# "
                    doc = replace(doc, m.match => m.captures[1]*"*"*m.captures[3]*"*\n"*"≡"^(length(m.captures[3])), count = 1)
                elseif m.captures[2] == "!!! "
                    doc = replace(doc, m.match => m.captures[1]*"__"*m.captures[3]*"__\n", count = 1)
                else
                    doc = replace(doc, m.match => m.captures[1]*"**"*m.captures[3]*"**\n"*"≡"^(length(m.captures[3])), count = 1)
                end
            end
            doc = replace(doc, r"(```.+)\n" => "```julia\n")
            doc = replace(doc, "```\n" => "```")
            for m in eachmatch(r"\[([^ ]*)\]\(@ref\)",doc)
                doc = replace(doc, m.match => "`"*m.captures[1]*"`", count = 1)
            end
            docs = split_message(doc)
            i = 1
            while i ≤ length(docs)
                if length(prod(docs[i:end])) ≤ 2000
                    reply(c, m, prod(docs[i:end]))
                    i = length(docs) + 1
                else
                    reply(c, m, docs[i])
                    i += 1
                end             
            end
        catch ex
            @show ex
            reply(c, m, "Sorry, it didn't work.")
        end
    end
    return nothing
end

