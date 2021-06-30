# External functions
include("./github_exts/github_profile.jl")
include("./github_exts/_github_organization_data.jl")


function commander(c::Client, m::Message, ::Val{:github})
    startswith(m.content, COMMAND_PREFIX * r"gh") || return

    github_suffixes = ("issue", "pr", "repo", "profile", "org")

    regex = Regex(COMMAND_PREFIX * raw"gh( [a-zA-Z]*)? *(.*)$")

    matches = match(regex, m.content)

    if isnothing(matches) || matches.captures[1] ∈ (" help", nothing)
        help_commander(c, m, :github)
    else
        suffix = strip(matches.captures[1])
        if suffix ∈ github_suffixes
            handle_github_commander(c, m, suffix, strip(matches.captures[2]))
        else
            reply(
                c,
                m,
                "Sorry, I don't understand your request; use `gh help` for help",
            )
        end
    end
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:github})
    return reply(
        c,
        m,
        """
        Retrieves github information. Includes profiles, issues, repo, and pull requests.
        Usage: `gh <issue|pr|repo|profile|org> <query>`
        Examples:
        `gh issue [number] [repo]`
        `gh issue [number] [owner]/[repo]` to be more specific

        `gh profile [username]`

        `gh org [org_name]`

        `gh pr [number] [repo]`
        `gh pr [number] [owner]/[repo]`

        `gh repo HoJBot.jl`
        `gh repo Humans-of-Julia/HoJBot.jl` to be more specific
        """,
    )
end

function handle_github_commander(c::Client, m::Message, suffix, query)
    query == "" && return reply(c, m, "Empty query not allowed")

    if suffix == "profile"
        _github_profile_command(c, m, query)
    elseif suffix == "org"
        _github_organization_data(c, m, query)
    else
        reply(c, m, "Sorry. Command not yet implemented.")
    end
    return nothing
end
