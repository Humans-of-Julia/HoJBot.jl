"""
This file contains tools to generate, and save to JSON, two Ditcs,
one with the pairs of names and their docstrings, and the other with
the pairs of names and the packages they appear in. See [`main`](@ref).

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

The second option makes more sense, since one would do this after
adding new packages to the environment, so their docstrings get added
to the lists.
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
    get_pkg_docs(pkg::String; all::Bool = false, imported::Bool = false)::Dict{String, String}

Return a Dict with the names (keys) and docstrings (values) of a given package.

Optional keyword arguments inherited from `Base.names`:
* If `all` is true, then the list also includes non-exported names defined in
  the module, deprecated names, and compiler-generated names.
* If `imported` is true, then names explicitly imported from other modules are also included.
"""
function get_pkg_docs(pkg::String; all::Bool = false, imported::Bool = false)::Dict{String, String}
    pkg_docs = Dict{String, String}()
    try
        eval(Expr(:import, Expr(:., Symbol(pkg))))
        for name in names(eval(Symbol(pkg)), all=all, imported=imported)
            doc = string(eval(:(Base.Docs.@doc $(Symbol(pkg)).$(Symbol(name)))))
            if !startswith(string(name), "#")
                if !occursin("No documentation found", doc) || occursin("[1]", doc)
                    push!(pkg_docs, string(name) => string(eval(:(Base.Docs.@doc $(Symbol(pkg)).$name))))
                end
            end
        end
    catch ex
        nothing
    end
    @info "$(length(pkg_docs)) names retrieved from package $pkg"
    return pkg_docs
end

"""
    get_all_docs(all::Bool = false, imported::Bool = false)::Dict{String, Dict{String, String}}

Return a Dict with the packages (keys) and name => docstring pairs (values)
of all available packages.

Optional keyword arguments inherited from `Base.names`:
* If `all` is true, then the list also includes non-exported names defined in
  the module, deprecated names, and compiler-generated names.
* If `imported` is true, then names explicitly imported from other modules are also included.
"""
function get_all_docs(; all::Bool = false, imported::Bool = false)::Dict{String, Dict{String, String}}
    all_docs = Dict{String, Dict{String, String}}()
    for pkg in list_of_pkgs()
        if pkg == "Keywords"
            Keywords = ["baremodule", "begin", "break", "catch", "const",
                "continue", "do", "else", "elseif", "end", "export", "false",
                "finally", "for", "function", "global", "if", "import",
                "let", "local", "macro", "module", "quote", "return",
                "struct", "true", "try", "using", "while", "abstract type",
                "mutable struct", "primitive type", "where", "in", "isa"]
            pkg_docs = Dict{String, String}()
            for name in Keywords
                if !startswith(string(name), "#")
                    doc = string(eval(:(Base.Docs.@doc $(Symbol(name)))))
                    if !occursin("No documentation found", doc) || occursin("[1]", doc)
                        push!(pkg_docs, string(name) => doc)
                    end
                end
            end
            push!(all_docs, pkg => pkg_docs)
            @info "$(length(pkg_docs)) keyword names retrieved"
        else
            pkg_docs = get_pkg_docs(pkg, all=all, imported=imported)
            if length(pkg_docs) > 0
                push!(all_docs, pkg => pkg_docs)
            end
        end
    end
    @info "$(length(all_docs)-2) packages found with docstrings"
    return all_docs
end

"""
    save_docs(docs_filename::String, all_docs::Dict{String, Dict{String, String}})::Nothing

Save all available documentation as a JSON file with the given filename.
"""
function save_docs(filename::String, all_docs::Dict{String, Dict{String, String}})::Nothing
    write(filename, JSON.json(all_docs, 4))
    return nothing
end

"""
    load_all_docs(filename)::Dict{String, Dict{String, String}}

Return a Dict with the packages (keys) and name => docstring pairs (values)
of all available packages in the given JSON file.
"""
function load_docs(filename)::Dict{String, Dict{String, String}}
    all_docs = JSON.parsefile(filename)
    all_docs = convert(Dict{String, Dict{String, String}}, docs)
    return all_docs
end

"""
    get_all_names(docs::Dict{String, Dict{String, String}})::Dict{String,Vector{String}}

Return a Dict with all the names (keys) available with docstrings and all 
the packages (values) where the given name is defined.
"""
function get_all_names(all_docs::Dict{String, Dict{String, String}})::Dict{String,Vector{String}}
    all_names = Dict{String,Vector{String}}()
    for (pkg, docs) in all_docs
        for name in keys(docs)
            if name in keys(all_names)
                push!(all_names[name], pkg)
            else
                push!(all_names, name => [pkg])
            end
        end
    end
    @info "$(length(all_names)) total names found."
    return all_names
end

"""
    save_names(filename::String, all_names::Dict{String,Vector{String}})::Nothing

Save to a JSON file the list of names and the associated list of corresponding
packages each name appears in.
"""
function save_names(filename::String, all_names::Dict{String,Vector{String}})::Nothing
    write(filename, JSON.json(all_names, 4))
    return nothing
end

"""
    load_names(filename::String)::Nothing

Save to a JSON file the list of names and the associated list of corresponding
packages each name appears in.
"""
function load_names(filename::String)::Dict{String,Vector{String}}
    all_names = JSON.parsefile(filename)
    all_names = convert(Dict{String,Vector{String}}, all_names)
    return all_names
end

"""
    main(;all=true, imported=false)

Generate two JSON files, one with the list of names and their docstrings
and the other with the list of names and the packages they appear in.

The packages are taken from the active environment, which should contain
at least `Pkg` and `JSON`.

The JSON files are saved, respectively in "../../data/docs/all_docs.json"
and "../../data/docs/all_names.json", both relative to the script path.
"""
function main(;all=true, imported=false)
    all_docs = get_all_docs(all=all, imported=imported)
    all_names = get_all_names(all_docs)
    save_docs(joinpath(@__DIR__, "..", "data", "docs", "all_docs.json"), all_docs)
    save_names(joinpath(@__DIR__, "..", "data", "docs", "all_names.json"), all_names)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

