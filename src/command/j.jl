# implement julia_commander for showing docstrings

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

function commander(c::Client, m::Message, ::Val{:julia_doc})
    # @info "julia_commander called"
    # @info "Message content" m.content m.author.username m.author.discriminator
    startswith(m.content, COMMAND_PREFIX * "j") || return
    regex = Regex(COMMAND_PREFIX * raw"j(\?| help| doc| packages| stats)? *(.*)$")
    matches = match(regex, m.content)
    if matches === nothing || matches.captures[1] in (" help", nothing)
        help_commander(c, m, Val(:julia_doc))
    elseif matches.captures[1] in ("?", " doc")
        handle_julia_help_commander(c, m, matches.captures[2])
    elseif matches.captures[1] == " packages"
        handle_julia_package_list(c, m)
    elseif matches.captures[1] == " stats"
        handle_doc_stats(c, m, matches.captures[2])
    else
        reply(c, m, "Sorry, I don't understand the request; use `j help` for help")
    end
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:julia_doc})
    # @info "Sending help for message" m.id m.author
    reply(c, m, """
        The `j` commands shows the docstring of names in the Base and other selected packages,
        as well as statistics of its use.

        How to use the `j` command:
        ```
        j help
        j? <name>
        j doc <name>
        j packages
        j stats <name>
        j stats <place> <number>
        ```
        `j help` returns this help
        `j packages` shows which packages are available for showing their docstrings (incomplete)
        `j? <name>` and `j doc <name>` return the documentation for `<name>`
        `j stats <name>` return how many times the docstring for `name` has been queried.
        `j stats <place> <number>` return the top (if `place` is equal to either "top" or "head") or the bottom (if `place` is equal to either "bottom" or "tail") `number` names that have been queried.
        """)
    return nothing
end

function handle_julia_help_commander(c::Client, m::Message, name)
    # @info "julia_help_commander called"
    try
        doc = string(eval(:(Base.Docs.@doc $(Symbol(name)))))
        doc = parse_doc(doc)
        channel = @discord get_channel(c, m.channel_id)
        if !occursin("No documentation found", doc)
            count = update_names_count(
                "namescount", name,
                m.channel_id, channel.name)
            doc *= "\n*(Count number for `$name`: $count)*"
        end
        if startswith(doc, r"```(?!julia)")
            doc = replace(doc, "```" => "```\n", count=1)
        end
        docs = split_message(doc, extrastyles = [r"\n≡.+\n", r"n-.+\n"])
        for doc_chunk in docs
            # @show doc_chunk
            reply(c, m, doc_chunk)
        end
    catch ex
        @show ex
        reply(c, m, "Sorry, it didn't work.")
    end
    return nothing
end

function handle_doc_stats(c::Client, m::Message, captured::AbstractString)
    # @info "handle_doc_stats called"
    try
        r = match(r"(top|head|bottom|tail) +(\d*) *$", captured)
        if captured == ""
            statsmgs = stats_namescount("namescount")
        elseif r === nothing
            statsmgs = stats_namescount("namescount", name=strip(captured))        
        else
            place = r.captures[1] in ("top", "head") ? "top" : "bottom"
            statsmgs = stats_namescount("namescount", place=place, number=parse(Int,r.captures[2]))
        end
        reply(c, m, statsmgs)
    catch ex
        @show ex
        reply(c, m, "Sorry, it didn't work.")
    end
    return nothing
end

function handle_julia_package_list(c::Client, m::Message)
    reply(c, m, "Packages available with docstrings:\n≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡\n `Base`")
end
