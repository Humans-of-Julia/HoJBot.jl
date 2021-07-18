# TODO: temporary until the start of JuliaCon
# JuliaCon.debugmode(true)

function commander(c::Client, m::Message, ::Val{:julia_con})
    startswith(m.content, COMMAND_PREFIX * "jc ") || m.content == COMMAND_PREFIX * "jc" || return

    regex = Regex(COMMAND_PREFIX * raw"jc( help| juliacon2021| now| today)? *(.*)$")

    matches = match(regex, m.content)

    if matches === nothing || matches.captures[1] ∈ (" help", nothing)
        help_commander(c, m, :julia_con)
    elseif matches.captures[1] == " juliacon2021"
        @info "juliacon2021 was required" m.content m.author.username m.author.discriminator
        jc_juliacon2021(c, m)
    elseif matches.captures[1] == " now"
        @info "now was required" m.content m.author.username m.author.discriminator
        jc_now(c, m)
    elseif matches.captures[1] == " today"
        @info "today was required" m.content m.author.username m.author.discriminator
        jc_today(c, m)
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

function jc_juliacon2021(c::Client, m::Message)
    reply(c, m, "Welcome to JuliaCon 2021! Find more information at https://juliacon.org/2021/.")
    return nothing
end

function jc_now(c::Client, m::Message)
    if JuliaCon.get_running_talks(; now=FAKENOW) === nothing
        @info "There is no JuliaCon program today!"
    else
        reply(c, m, JuliaCon.now(now=FAKENOW, output=:text))
    end
    return nothing
end

function split_pretty_table(str)
    lines = split(str, "\n")
    acc = "```\n"
    strings = Vector{String}()
    for line in lines
        if sum(length, [acc, line]) ≤ 1996
            acc *= "\n" * line
        else
            push!(strings, acc * "\n```")
            acc = "```\n" * line
        end
    end
    push!(strings, acc * "\n```")
    return strings
end

function jc_today(c::Client, m::Message)
    if JuliaCon.get_today(; now=FAKENOW) === nothing
        @info "There is no JuliaCon program today!"
    else
        strings = Vector{String}()
        aux = JuliaCon.today(now = FAKENOW, output = :text)
        tables, legend = aux[1:end-1], aux[end]
        for t in tables, str in split_pretty_table(t)
            push!(strings, str)
        end
        push!(strings, legend)
        foreach(s -> reply(c, m, s), strings)
    end
    return nothing
end
