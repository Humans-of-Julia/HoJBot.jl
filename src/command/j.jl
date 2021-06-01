# implement julia_commander for showing docstrings

function parse_doc(doc::AbstractString)
    doc = replace(doc, r"\n\n\n+" => "\n\n")
    capture_ranges = [m.offset:m.offset+ncodeunits(m.match)-1 for m in eachmatch.(r"(```.+?```)"s, doc)]
    for m in eachmatch(r"(^|\n)(#+ |!!! )(.*)\n",doc)
        if all(rg -> m.offset ∉ rg, capture_ranges)
            if m.captures[2] == "# "
                doc = replace(doc, m.match => m.captures[1]*"**"*m.captures[3]*"**\n"*"≡"^(length(m.captures[3])), count = 1)
            elseif m.captures[2] == "!!! "
                doc = replace(doc, m.match => m.captures[1]*"__"*m.captures[3]*"__\n", count = 1)
            else
                doc = replace(doc, m.match => m.captures[1]*"*"*m.captures[3]*"*\n"*"-"^(length(m.captures[3])), count = 1)
            end
        end
    end
    doc = replace(doc, r"(```.+)\n" => "```julia\n")
    doc = replace(doc, "```\n\n" => "```\n")
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
        channel = @discord get_channel(c, m.channel_id)
        all_names = load_names(joinpath(@__DIR__, "..", "..", "data", "docs", "all_names.json"))
        pkg_in_name, name = occursin('.', name) ? split(name, '.') |> u -> (first(u), last(u)) : ("", name)
        if name in keys(all_names)
            all_docs = load_docs(joinpath(@__DIR__, "..", "..", "data", "docs", "all_docs.json"))
            doc_in_pkgs = Dict{String, String}()
            for pkg in all_names[name]
                if pkg_in_name in ("", pkg)
                    push!(doc_in_pkgs, pkg => all_docs[pkg][name])
                end
            end
            
            if length(doc_in_pkgs) > 0
                for (k,v) in doc_in_pkgs
                    if k in ("Base", "Keywords")
                        doc = v
                    else
                        doc = "*In Package* `$k`:\n" * v
                    end
                    doc = parse_doc(doc)
                    docs = split_message(doc, extrastyles = [r"\n.*\n≡.+\n", r"\n.*\n-+\n"])
                    for doc_chunk in docs
                        # @show doc_chunk
                        reply(c, m, doc_chunk)
                    end
                end
                
                count = update_names_count(
                    "namescount", name,
                    m.channel_id, channel.name)
                reply(c, m, "*(Count number for `$name`: $count)*")
            else
                reply(c, m, "No documentation for `$name` found in package `$pkg`")
            end
        else
            reply(c, m, "No documentation found.")
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
    all_docs_filename = joinpath(@__DIR__, "..", "..", "data", "docs", "all_docs.json")
    if isfile(all_docs_filename)
        all_docs = load_docs(all_docs_filename)
        msg = "Besides the keywords and Base, there are $(length(all_docs)-2) packages " *
            "available with docstrings:\n\n" *
            join(sort(collect(keys(all_docs))), ", ") * "."
    else
        msg = "No packages available with docstrings"
    end
    reply(c, m, msg)
end
