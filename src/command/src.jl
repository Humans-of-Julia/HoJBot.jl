const sources_url = LittleDict([
    "HoJBot" => "https://github.com/Humans-of-Julia/HoJBot.jl",
])

"""
Returns the url of the source repo of HojBot.
"""
function commander(c::Client, m::Message, ::Val{:source})
    startswith(m.content, COMMAND_PREFIX * "src") ||  return
    regex = Regex(COMMAND_PREFIX * raw"src (repo|repository|help) *(.*)$") # will add something soon to return specific code of commands
    matches = match(regex, m.content)
    if matches === nothing || matches.captures[1] == "repo" || matches.captures[1] == "repository"
        reply(c, m, sources_url["HoJBot"])
    elseif matches.captures[1] == "help"
        help_commander(c, m, :source)
    end
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:source})
    reply(c, m, """
        Source command usage.
        Returns the Github repository url of HojBot:
        ```
        source
        source repo|repository
        ```
        """
    )
end
