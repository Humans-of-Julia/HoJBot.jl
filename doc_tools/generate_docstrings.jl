"""
Tools to generate, and save to JSON, info about packages, names and docstrings.

You may either call this file from the shell, e.g. with (from the
directory where the script resides)

```zsh
% julia --project=@. generate_docstring.jl
```

or, which is more common, from the Julia REPL, with

```julia
julia> include("generate_docstring.jl")

julia> main()
```

The second option makes more sense, since one would usually activate
and add packages to the environment, and then run `main()` to generate
the JSON files, with the updated set of packages.

See [`main`](@ref) for more details.
"""

using Pkg
using JSON

"""
    list_of_pkgs()::Vector{String}

Return the list of Packages available for import, discarding jll packages.
"""
function list_of_pkgs()::Vector{String}
    pkgs = Vector{String}()
    push!(pkgs, "Keywords")
    push!(pkgs, "Base")
    for pkg_info in values(Pkg.dependencies())
        if !endswith(pkg_info.name, "_jll")
            push!(pkgs, pkg_info.name)
        end
    end
    @info "$(length(pkgs)-2) packages found"
    return pkgs
end

"""
    get_pkg_docs(pkg::String)::Dict{String, Vector{String}}

Return a Dict with the names as keys, and with each value being a vector,
where the first element indicates whether the associated name is "exported"
or "nonexported" from the package, while the second element contains the
corresponding docstring.

Only names with meaningful docstrings are retrieved.
"""
function get_pkg_docs(pkg::String)::Dict{String, Vector{String}}
    pkg_docs = Dict{String, Vector{String}}()
    num_exported = 0
    try
        eval(Expr(:import, Expr(:., Symbol(pkg))))
        names_exported = names(eval(Symbol(pkg)))
        for name in names(eval(Symbol(pkg)), all=true)
            doc = string(eval(:(Base.Docs.@doc $(Symbol(pkg)).$(Symbol(name)))))
            if !startswith(string(name), "#")
                if !occursin("No documentation found", doc) || occursin("[1]", doc)
                    exported = name in names_exported ? "exported" : "nonexported"
                    num_exported += exported == "exported" ? 1 : 0
                    push!(pkg_docs, string(name) => [exported, string(eval(:(Base.Docs.@doc $(Symbol(pkg)).$name)))])
                end
            end
        end
    catch
        nothing
    end
    @info "$(length(pkg_docs)) names retrieved ($num_exported being exported) from package $pkg"
    return pkg_docs
end

"""
    get_all_docs()::Dict{String, Dict{String, Vector{String}}}

Return a Dict with the packages as keys and the info about the package
as values (see [get_pkg_docs](@ref)).
"""
function get_all_docs()::Dict{String, Dict{String, Vector{String}}}
    all_docs = Dict{String, Dict{String, Vector{String}}}()
    Keywords = [
        "baremodule", "begin", "break", "catch", "const",
        "continue", "do", "else", "elseif", "end", "export", "false",
        "finally", "for", "function", "global", "if", "import",
        "let", "local", "macro", "module", "quote", "return",
        "struct", "true", "try", "using", "while", "abstract type",
        "mutable struct", "primitive type", "where", "in", "isa"
    ]
    for pkg in list_of_pkgs()
        if pkg == "Keywords"
            pkg_docs = Dict{String, Vector{String}}()
            for name in Keywords
                if !startswith(string(name), "#")
                    doc = string(eval(:(Base.Docs.@doc $(Symbol(name)))))
                    if !occursin("No documentation found", doc) || occursin("[1]", doc)
                        push!(pkg_docs, string(name) => Vector{String}(["exported", doc]))
                    end
                end
            end
            push!(all_docs, pkg => pkg_docs)
            @info "$(length(pkg_docs)) keyword names retrieved"
        else
            pkg_docs = get_pkg_docs(pkg)
            if length(pkg_docs) > 0
                push!(all_docs, pkg => pkg_docs)
            end
        end
    end
    @info "$(length(all_docs)-2) packages found with docstrings"
    return all_docs
end

"""
    save_docs(docs_filename::String, all_docs::Dict{String, Dict{String, Vector{String}}})::Nothing

Save all available documentation info as a JSON file with the given filename.
"""
function save_docs(filename::String, all_docs::Dict{String, Dict{String, Vector{String}}})::Nothing
    write(filename, JSON.json(all_docs, 4))
    return nothing
end

"""
    load_all_docs(filename)::Dict{String, Dict{String, Vector{String}}}

Return a Dict with the all the available documentation info present
in the given JSON file.
"""
function load_docs(filename)::Dict{String, Dict{String, Vector{String}}}
    all_docs = JSON.parsefile(filename)
    all_docs = convert(Dict{String, Dict{String, Vector{String}}}, docs)
    return all_docs
end

"""
    get_all_names(docs::Dict{String, Dict{String, Vector{String}}})::Dict{String,Dict{String,String}}

Return a Dict with all the names (keys) available with docstrings and where
the values is another Dict whose keys are the packages where the name appears
in and the values indicate whether the name is "exported" from the packaged or
"nonexported".
"""
function get_all_names(all_docs::Dict{String, Dict{String, Vector{String}}})::Dict{String,Dict{String,String}}
    all_names = Dict{String,Dict{String,String}}()
    for (pkg, docs) in all_docs
        for name in keys(docs)
            if name in keys(all_names)
                push!(all_names[name], pkg => all_docs[pkg][name][1])
            else
                push!(all_names, name => Dict(pkg => all_docs[pkg][name][1]))
            end
        end
    end
    @info "$(length(all_names)) total names found."
    return all_names
end

"""
    save_names(filename::String, all_names::Dict{String,Dict{String,String}})::Nothing

Save to a JSON file the list of names and the corresponding package info
(see [`get_all_names`](@ref)).
"""
function save_names(filename::String, all_names::Dict{String,Dict{String,String}})::Nothing
    write(filename, JSON.json(all_names, 4))
    return nothing
end

"""
    load_names(filename::String)::Dict{String,Vector{Vector{String}}}

Return a Dict, read from the given JSON file, that contains the list of names
and the associated info from the packages each name appears in. (see [`get_all_names`](@ref)).
"""
function load_names(filename::String)::Dict{String,Dict{String,String}}
    all_names = JSON.parsefile(filename)
    all_names = convert(Dict{String,Dict{String,String}}, all_names)
    return all_names
end

"""
    main()

Generate, and save to JSON files, info about packages, names and docstrings.

The information is generated into two Dicts, and each Dict is saved in JSON format.

One Dict contains all the packages as keys, with each value being another Dict,
containing all the names in the package as keys, with the values being a vector,
where the first element indicates whether the name is "exported" or "nonexported"
from the package, and the second element contains the corresponding docstring.

The other Dict contains all the names as keys, with each value being another Dict,
whose keys are the packages where the name appears in and the values indicate
whether the name is "exported" from the packaged or "nonexported".

The JSON files are saved, respectively in "../../data/docs/all_docs.json"
and "../../data/docs/all_names.json", both relative to the script path.
"""
function main()
    all_docs = get_all_docs()
    all_names = get_all_names(all_docs)
    save_docs(joinpath(@__DIR__, "..", "data", "docs", "all_docs.json"), all_docs)
    save_names(joinpath(@__DIR__, "..", "data", "docs", "all_names.json"), all_names)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

