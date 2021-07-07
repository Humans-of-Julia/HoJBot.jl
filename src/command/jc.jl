using Base: julia_cmd
function commander(c::Client, m::Message, ::Val{:julia_con})
    startswith(m.content, COMMAND_PREFIX * "jc") || return

    regex = Regex(COMMAND_PREFIX * raw"jc( help| juliacon2021| now| today)? *(.*)$")

    matches = match(regex, m.content)

    if matches === nothing || matches.captures[1] ∈ (" help", nothing)
        help_commander(c, m, :julia_con)
    elseif matches.captures[1] == " juliacon2021"
        @info "juliacon2021 was required" m.content m.author.username m.author.discriminator
        juliacon2021(c, m, :julia_con)
    elseif matches.captures[1] == " now"
        @info "now was required" m.content m.author.username m.author.discriminator
        now(c, m, :julia_con)
    elseif matches.captures[1] == " today"
        @info "today was required" m.content m.author.username m.author.discriminator
        today(c, m, :julia_con)
    else
        reply(c, m, "Sorry, are you looking for information on JuliaCon 2021? Please check out `jc help`")
    end
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:julia_con})
    reply(c, m, """
        How to look for information about JuliaCon 2021 with the `jc` command:
        ```
        jc help
        jc juliacon2021
        jc now
        jc today
        ```
        `help` prints this message
        `juliacon2021` greets the users and provide a link to the official website
        `now` details the talks and events occuring right now on the different tracks
        `today` lists the talks and event of the day
        """)
end

function juliacon2021(c::Client, m::Message, ::Val{:julia_con})
    reply(c, m, "WIP: juliacon2021()")
end

function now(c::Client, m::Message, ::Val{:julia_con})
    reply(c, m, "WIP: now()")
end

function today(c::Client, m::Message, ::Val{:julia_con})
    reply(c, m, "WIP: today()")
end
