function commander(c::Client, m::Message, ::Val{:julia_con})
    command = extract_command("jc", m.content)
    args = split(command)
    @debug "parse result" command args

    if length(args) == 0 || args[1] ∉ ["2021", "now", "today", "tomorrow", "day"] # next is not available yet
        help_commander(c, m, :julia_con)
        return nothing
    end

    arg = (occursin(r"[0-9]+", args[1]) ? "jc" : "") * args[1]
    return jc_execute(c, m, Symbol(arg), args[2:end])
end

jc_execute(c, m, arg::Symbol, args) = jc_execute(c, m, Val(arg), args)

function jc_execute(c, m, ::Val{:jc2021}, args)
    @info "2021 was required" m.content m.author.username m.author.discriminator
    return jc_juliacon2021(c, m)
end

function jc_execute(c, m, ::Val{:now}, args)
    @info "now was required" m.content m.author.username m.author.discriminator args

    tz_arg = isempty(args) || !TimeZones.istimezone(args[1]) ? "UTC" : args[1]
    current = ZonedDateTime(now(), TimeZone(tz_arg))
    # current = ZonedDateTime(Dates.DateTime("2021-07-30T21:30:00.000"), TimeZone(tz_arg))
    @info "now command" tz_arg current

    if isempty(JuliaCon.get_running_talks(; now=current))
        not_now = "There is no JuliaCon program now."
        @info not_now
        today = " Try `jc today`"
        schedule = "(Full schedule: https://live.juliacon.org/agenda)"
        reply(c, m, not_now * today * "\n" * schedule)
    else
        reply(c, m, JuliaCon.now(; now=current, output=:text))
    end
    return nothing
end

function jc_execute(c, m, ::Val{:today}, args)
    tz_arg = isempty(args) || !TimeZones.istimezone(args[1]) ? "UTC" : args[1]
    dt = now(TimeZone(tz_arg))
    jc_today(c, m, dt)
    return nothing
end

function jc_execute(c, m, ::Val{:tomorrow}, args)
    tz_arg = isempty(args) || !TimeZones.istimezone(args[1]) ? "UTC" : args[1]
    dt = now(TimeZone(tz_arg)) + Day(1)
    jc_today(c, m, dt)
    return nothing
end

function jc_execute(c, m, ::Val{:next}, args)
    @info "Calling :next"
end

function jc_execute(c, m, ::Val{:day}, args)
    zonedDT = ZonedDateTime(Date(args[1]), tz"UTC")
    jc_today(c, m, zonedDT)
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:julia_con})
    return reply(
        c,
        m,
        """
        How to look for information about JuliaCon 2021 with the `jc` command:
        ```
        jc help
        jc 2021
        jc now
        jc today [timezone]
        jc tomorrow [timezone]
        jc day <xxxx-mm-dd>
        ```
        `help` prints this message
        `2021` greets the users and provide a link to the official website of year 2021's edition
        `now` details the talks and events occuring right now on the different tracks
        `today`, `tomorrow`, `day` lists the talks and event of the day. [timezone] is an optional argument which need to be valid following the TimeZones.jl package

        Examples
        ```
        jc today Asia/Tokyo
        jc tomorrow America/Juneau
        jc day 2021-07-27
        ```
        """,
    )
end

function jc_juliacon2021(c::Client, m::Message)
    reply(
        c,
        m,
        "Welcome to JuliaCon 2021! Find more information at https://juliacon.org/2021/.",
    )
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

function jc_today(c::Client, m::Message, zonedDT::ZonedDateTime)
    responses = jc_today(zonedDT)
    return foreach(s -> reply(c, m, s), responses)
end

function jc_today(zonedDT::ZonedDateTime)
    @info "jc_today" zonedDT
    aux = JuliaCon.today(; now=zonedDT, output=:text)
    if aux === nothing
        not_today = "There is no JuliaCon program at $(zonedDT)"
        schedule = "(Full schedule: https://live.juliacon.org/agenda)"
        return [not_today * "\n" * schedule]
    else
        strings = Vector{String}()
        tables, legend = aux[1:(end - 1)], aux[end]
        for t in tables, str in split_pretty_table(t)
            push!(strings, str)
        end
        push!(strings, legend)
        return strings
    end
end
