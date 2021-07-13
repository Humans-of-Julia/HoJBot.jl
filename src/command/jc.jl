# TODO: temporary until the start of JuliaCon
# JuliaCon.debugmode(true)

function commander(c::Client, m::Message, ::Val{:julia_con})
    startswith(m.content, COMMAND_PREFIX * "con") || return

    regex = Regex(COMMAND_PREFIX * raw"con( help| juliacon2021| now| today)? *(.*)$")

    matches = match(regex, m.content)

    if matches === nothing || matches.captures[1] ∈ (" help", nothing)
        help_commander(c, m, :julia_con)
    elseif matches.captures[1] == " juliacon2021"
        @info "juliacon2021 was required" m.content m.author.username m.author.discriminator
        _juliacon2021(c, m)
    elseif matches.captures[1] == " now"
        @info "now was required" m.content m.author.username m.author.discriminator
        _now(c, m)
    elseif matches.captures[1] == " today"
        @info "today was required" m.content m.author.username m.author.discriminator
        _today(c, m)
    else
        reply(c, m, "Sorry, are you looking for information on JuliaCon 2021? Please check out `con help`")
    end
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:julia_con})
    reply(c, m, """
        How to look for information about JuliaCon 2021 with the `con` command:
        ```
        con help
        con juliacon2021
        con now
        con today
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
    current_talks = JuliaCon.get_running_talks(; now=FAKENOW)
    if isnothing(current_talks)
        @info "There is no JuliaCon program today!"
        return nothing
    end

    str = ""
    for (track, talk) in current_talks
        str *= """
        $track
        \t$(talk.title) ($(talk.type))
        \t├─ $(JuliaCon.speakers2str(talk.speaker))
        \t└─ $(talk.url)
        """
        # printstyled(track; bold=true, color=_track2color(track))
    end
    str *= "\n(Full schedule: https://pretalx.com/juliacon2021/schedule)"
    reply(c, m, str)
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
    track_schedules = JuliaCon.get_today(; now=FAKENOW)
    if track_schedules === nothing
        @info "There is no JuliaCon program today!"
        return nothing
    end

    # @info "debug 1"

    track = nothing
    terminal_links = JuliaCon.TERMINAL_LINKS

    # @info "debug 2"


    str = ""
    header = (["Time", "Title", "Type", "Speaker"],)
    for (tr, talks) in track_schedules
        !isnothing(track) && tr != track && continue
        # h_current = JuliaCon._get_current_talk_highlighter(talks; now=FAKENOW)
        data = Matrix{Union{String, URLTextCell}}(undef, length(talks), 4)
        for (i, talk) in enumerate(talks)
            data[i, 1] = talk.start
            data[i, 2] = terminal_links ? URLTextCell(talk.title, talk.url) : talk.title
            data[i, 3] = JuliaCon.abbrev(talk.type)
            data[i, 4] = JuliaCon.speakers2str(talk.speaker)
        end
        str *= pretty_table(
            String, data;
            title=tr,
            title_crayon=Crayon(; foreground=JuliaCon._track2color(tr), bold=true),
            header=header,
            # header_crayon=header_crayon,
            # border_crayon=border_crayon,
            # highlighters=(JuliaCon.h_times, JuliaCon.h_current),
            tf=tf_unicode_rounded,
            alignment=[:c, :l, :c, :l],
        ) * "\n"
    end

    # @info "debug 3" strings

    strings = split_pretty_table(str)

    legend = """
    Currently running talks are highlighted in yellow (or not cause WIP).

    $(JuliaCon.abbrev(JuliaCon.Talk)) = Talk, $(JuliaCon.abbrev(JuliaCon.LightningTalk)) = Lightning Talk, $(JuliaCon.abbrev(JuliaCon.SponsorTalk)) = Sponsor Talk, $(JuliaCon.abbrev(JuliaCon.Keynote)) = Keynote,
    $(JuliaCon.abbrev(JuliaCon.Workshop)) = Workshop, $(JuliaCon.abbrev(JuliaCon.Minisymposia)) = Minisymposia, $(JuliaCon.abbrev(JuliaCon.BoF)) = Birds of Feather

    Check out https://pretalx.com/juliacon2021/schedule for more information.
    """

    push!(strings, legend)
    foreach(s -> reply(c, m, s), strings)
    return nothing
end
