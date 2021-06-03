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
    regex = Regex(COMMAND_PREFIX * raw"j(\?| help| doc| packages| package| stats| top| bottom)? *(.*)$")
    matches = match(regex, m.content)
    if matches === nothing || matches.captures[1] in (" help", nothing)
        help_commander(c, m, Val(:julia_doc))
    elseif matches.captures[1] in ("?", " doc")
        handle_julia_help_commander(c, m, matches.captures[2])
    elseif matches.captures[1] == " packages"
        handle_julia_package_list(c, m)
    elseif matches.captures[1] == " package"
        handle_julia_names_in_package(c, m, matches.captures[2])
    elseif matches.captures[1] in (" stats", " top", " bottom")
        handle_doc_stats(c, m, matches.captures[1], matches.captures[2])
    else
        reply(c, m, "Sorry, I don't understand the request; use `j help` for help")
    end
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:julia_doc})
    # @info "Sending help for message" m.id m.author
    reply(c, m, """
        The `j` command shows the docstring of keywords, names in Base and names in other selected packages. Only names with meaningful help information have been recorded from each package.
        
        The `j` command also gives statistics on the names that have been queried, via `j stats`.

        To see which packages have been added, use `j packages`. If you would like a particular package to be added, just let us know.

        Here is the list of all available `j` commands and their use:
        ```
        j help
        j? <name>
        j doc <name>
        j packages
        j package <PkgName>
        j stats [<name>]
        j top [<number>]
        j bottom [<number>]
        ```
        * `j help` returns this help.
        * `j packages` shows which packages are available with names.
        * `j package <PkgName>` shows which names have bee recorded from to package `<PkgName>`.
        * `j? <name>` and `j doc <name>` return the documentation for `<name>`
        * `j stats <name>` return how many times the docstring for `name` has been queried.
        * `j top [<number>]` return the top 10 names that have been queried (or top `number`, if given).
        * `j bottom [<number>]` return the bottom 10 names that have been queried (or bottom `number`, if given).
        """)
    return nothing
end

function handle_julia_help_commander(c::Client, m::Message, name::AbstractString)
    # @info "julia_help_commander called"
    try
        name = strip(name)
        name = replace(name, r"\s{2,}" => " ")
        channel = @discord get_channel(c, m.channel_id)
        all_names = load_names(joinpath(@__DIR__, "..", "..", "data", "docs", "all_names.json"))
        pkg_in_name, name = occursin('.', name) ? split(name, '.') |> u -> (first(u), last(u)) : ("", name)
        if name in keys(all_names)
            all_docs = load_docs(joinpath(@__DIR__, "..", "..", "data", "docs", "all_docs.json"))
            doc_in_pkgs = Dict{String, String}()
            for pkg in all_names[name]
                if pkg_in_name in ("", pkg)
                    push!(doc_in_pkgs, pkg => all_docs[pkg][name][2])
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
                    docs = split_message(doc, extrastyles = [r"\n.*\n≡.+\n", r"\n.*\n-+\n", r"[^\s]+"])
                    for doc_chunk in docs
                        # @info doc_chunk
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
        @info ex
        reply(c, m, "Sorry, it didn't work.")
    end
    return nothing
end

function handle_doc_stats(c::Client, m::Message, captured1::AbstractString, captured2::AbstractString)
    # @info "handle_doc_stats called"
    captured2 = strip(captured2)
    captured2 = replace(captured2, r"\s{2,}" => " ")
    try
        if captured1 == " stats"
            if captured2 == ""
                statsmgs = stats_namescount("namescount")
            else
                statsmgs = stats_namescount("namescount", name=captured2)
            end
        elseif captured1 in (" top", " bottom")
            if captured2 != "" && all(isdigit,captured2) 
                statsmgs = stats_namescount("namescount", place=strip(captured1), number=max(1, parse(Int,captured2)))
            else
                statsmgs = stats_namescount("namescount", place=strip(captured1))
            end
        end
        reply(c, m, statsmgs)
    catch ex
        @info ex
        reply(c, m, "Sorry, it didn't work.")
    end
    return nothing
end

function handle_julia_package_list(c::Client, m::Message)
    all_docs_filename = joinpath(@__DIR__, "..", "..", "data", "docs", "all_docs.json")
    if isfile(all_docs_filename)
        all_docs = load_docs(all_docs_filename)
        msg = "Besides the **keywords** and **Base**, there are $(length(all_docs)-2) packages " *
            "available with recorded names:\n\n" *
            join(sort(collect(keys(all_docs))), ", ") * "."
    else
        msg = "No packages available."
    end
    reply(c, m, msg)
end

function handle_julia_names_in_package(c::Client, m::Message, pkg::AbstractString)
    pkg = strip(pkg)
    pkg = replace(pkg, r"\s{2,}" => " ")
    # @info pkg
    all_names_filename = joinpath(@__DIR__, "..", "..", "data", "docs", "all_names.json")
    all_docs_filename = joinpath(@__DIR__, "..", "..", "data", "docs", "all_docs.json")
    if isfile(all_names_filename) && isfile(all_docs_filename)
        all_docs = load_docs(all_docs_filename)
        all_names = load_names(all_names_filename)
        pkg_list = [name for (name, pkgs) in all_names if pkg in pkgs]
        pkg_list_exported = [name for name in pkg_list if all_docs[pkg][name][1] == "exported"]
        pkg_list_nonexported = filter(name -> name ∉ pkg_list_exported, pkg_list) 
        # @info pkg_list
        if length(pkg_list) > 0
            #msg = "$(length(pkg_list)) names recorded from package `$pkg`:\n\n" *
            #  join(sort(pkg_list), ", ") * "."
            msg = ""
            if length(pkg_list_exported) == 0
                msg *= "**There are no exported names recorded from package `$pkg`:**\n\n"
            elseif length(pkg_list_exported) == 1
                msg *= "**There is 1 exported name recorded from package `$pkg`:**\n\n"
            else
                msg *= "**There are $(length(pkg_list_exported)) exported names recorded from package `$pkg`:**\n\n"
            end
            if length(pkg_list_exported) > 0
                msg *= join(sort(pkg_list_exported), ", ") * ".\n\n"
            end
            if length(pkg_list_nonexported) == 0
                msg *= "**Besides, there aren't any nonexported names:**\n\n"
            elseif length(pkg_list_nonexported) == 1
                msg *= "**Besides, there is 1 nonexported name:**\n\n"
            else
                msg *= "**Besides, there are $(length(pkg_list_nonexported)) non-exported names:**\n\n"
            end
            if length(pkg_list_nonexported) > 1
                msg *= join(sort(pkg_list_nonexported), ", ") * "."
            end              
        else
            msg = "No names found in `$pkg`."
        end
    else
        msg = "No packages available."
    end

    msg = split_message(msg)
    for msg_chunk in msg
        reply(c, m, msg_chunk)
    end
end
