const source_url = "https://github.com/Humans-of-Julia/HoJBot.jl"

"Returns the url of the source repo of HojBot."    
function source_commander(c::Client, m::Message)
    startswith(m.content, COMMAND_PREFIX * "source") ||  return
    regex = Regex(COMMAND_PREFIX * raw"source (repo|repository|help)$") # will add something soon to return specific code of commands
    matches = match(regex, m.content)
    if matches === nothing || matches.captures[1] == "repo" || matches.captures[1] == "repository"
        reply(c, m, source_url)
    elseif matches.captures[1] == "help"
        reply(c, m, """
                Source command usage.

                Returns the Github repository url of HojBot:

                ```
                source
                source repo|repository
                ```
                """) 
        # more commands coming soon

    end
    return nothing
end
