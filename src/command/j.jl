# implement julia_commander
# for the moment, only help is implemented

function filterranges(u::Vector{UnitRange{Int}})
    v = Vector{Int}()
    while length(u) > 1
        if all(m -> (u[1] ⊈ m), u[2:end])
            push!(v, u[1][end])
        end
        u = u[findall(m -> m ⊈ u[1], u[2:end]).+1]
    end
    if length(u) == 1
        push!(v,u[1][end])
    end
    return v
end

const STYLES = [
    r"```.+?```"s, r"`.+?`", r"~~.+?~~", r"_.+?_", r"__.+?__",
    r"\*.+?\*", r"\*\*.+?\*\*", r"\*\*\*.+?\*\*\*",
]

function split_message_fixed(text::AbstractString, chunk_limit::Int=2000; extraregex::Vector{Regex}=Vector{Regex}())
    length(text) <= chunk_limit && return String[text]
    chunks = String[]

    while !isempty(text)
        mranges = vcat(findall.(union(STYLES,extraregex),Ref(text))...)

        stop = maximum(filter(i -> length(text[1:i]) ≤ chunk_limit, filterranges(mranges)))

        # give up if first chunk cannot be broken down
        if stop == 0
            push!(chunks, strip(text))
            @warn "message could not be broken down into chunks smaller than the desired length $chunk_limit"
            return chunks
        end

        push!(chunks, strip(text[1:stop]))
        text = strip(text[stop+1:end])
    end

    return chunks
end

function parse_doc(doc::AbstractString)
    doc = replace(doc, r"\n\n\n+" => "\n\n")
    for m in eachmatch(r"(^|\n)(#+ |!!! )(.*)\n",doc)
        if m.captures[2] == "# "
            doc = replace(doc, m.match => m.captures[1]*"**"*m.captures[3]*"**\n"*"≡"^(length(m.captures[3])), count = 1)
        elseif m.captures[2] == "!!! "
            doc = replace(doc, m.match => m.captures[1]*"__"*m.captures[3]*"__\n", count = 1)
        else
            doc = replace(doc, m.match => m.captures[1]*"*"*m.captures[3]*"*\n"*"-"^(length(m.captures[3])), count = 1)
        end
    end
    doc = replace(doc, r"(```.+)\n" => "```julia\n")
    doc = replace(doc, "```\n" => "```")
    for m in eachmatch(r"\[([^ ]*)\]\(@ref\)",doc)
        doc = replace(doc, m.match => "`"*m.captures[1]*"`", count = 1)
    end
    return doc
end

function julia_commander(c::Client, m::Message)
    # @info "julia_commander called"
    # @info "Message content" m.content m.author.username m.author.discriminator
    startswith(m.content, COMMAND_PREFIX * "j") || return
    regex = Regex(COMMAND_PREFIX * raw"j(\?| help| doc)? *(.*)$")
    matches = match(regex, m.content)
    if matches === nothing || matches.captures[1] in (" help", nothing)
        help_commander(c, m, Val(:julia))
    elseif matches.captures[1] in ("?", " doc")
        handle_julia_help_commander(c, m, matches.captures[2])
    else
        reply(c, m, "Sorry, I don't understand the request; use `j help` for help")
    end
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:julia})
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

function handle_julia_help_commander(c::Client, m::Message, name)
    # @info "julia_help_commander called"
    if ';' ∈ name
        reply(c, m, "Sorry, no semicolon allowed in the help query")
    else
        try
            doc = string(eval(Meta.parse("Docs.@doc("*name*")")))
            doc = parse_doc(doc)
            docs = split_message_fixed(doc, extraregex = [r"\n≡.+\n", r"n-.+\n"])
            for doc_chunck in docs
                reply(c, m, doc_chunck)
            end
        catch ex
            @show ex
            reply(c, m, "Sorry, it didn't work.")
        end
    end
    return nothing
end
