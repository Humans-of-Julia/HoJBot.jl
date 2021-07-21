function commander(c::Client, m::Message, ::Val{:julia_con})
    command = extract_command("jc", m.content)
    args = split(command)
    @debug "parse result" command args

    if length(args) == 0 ||
        args[1] ∉ ["2021", "now", "today", "next", "tomorrow", "day"]
        help_commander(c, m, :julia_con)
        return
    end

    arg = (occursin(r"[0-9]*", args[1]) ? "jc" : "") * args[1]
    jc_execute(c, m, Symbol(arg), args[2:end])

end

jc_execute(c, m, arg::Symbol, args) = jc_execute(c, m, Val(arg), args)

function jc_execute(c, m, ::Val{:jc2021}, args)
    @info "2021 was required" m.content m.author.username m.author.discriminator
    jc_juliacon2021(c, m)
end

function jc_execute(c, m, ::Val{:now}, args)
    @info "now was required" m.content m.author.username m.author.discriminator args

    current = ZonedDateTime(now(), TimeZone(TimeZones.istimezone(args[1]) ? args[1] : "UTC"))

    if JuliaCon.get_running_talks(now = current) === nothing
        not_now = "There is no JuliaCon program now"
        @info not_now
        today = " Try `jc today`"
        schedule = "(Full schedule: https://pretalx.com/juliacon2021/schedule)"
        reply(c, m, not_now * today * "\n\n" * schedule)
    else
        reply(c, m, JuliaCon.now(now = current, output=:text))
    end
    return nothing
end

function jc_execute(c, m, ::Val{:today}, args)
    day = today(TimeZone(TimeZones.istimezone(args[1]) ? args[1] : "UTC"))
    return jc_execute(c, m, :day, [day])
end

function jc_execute(c, m, ::Val{:tomorrow}, args)
    day = today(TimeZone(TimeZones.istimezone(args[1]) ? args[1] : "UTC")) + Day(1)
    return jc_execute(c, m, :day, [day])
end

function jc_execute(c, m, ::Val{:next}, args)
    @info "Calling :next"
end

jc_execute(c, m, ::Val{:day}, args) = jc_today(c, m, args[1])

function help_commander(c::Client, m::Message, ::Val{:julia_con})
    reply(c, m, """
        How to look for information about JuliaCon 2021 with the `jc` command:
        ```
        jc help
        jc 2021
        jc now [timezone]
        jc today [timezone]
        jc day <xxxx-mm-dd>
        ```
        `help` prints this message
        `2021` greets the users and provide a link to the official website of year 2021's edition
        `now` details the talks and events occuring right now on the different tracks
        `today` lists the talks and event of the day
        """)
end

function jc_juliacon2021(c::Client, m::Message)
    reply(c, m, "Welcome to JuliaCon 2021! Find more information at https://juliacon.org/2021/.")
    return nothing
end

# function jc_now(c::Client, m::Message; tz = "UTC")
#     if JuliaCon.get_running_talks() === nothing
#         not_now = "There is no JuliaCon program now"
#         @info not_now
#         today = " Try `jc today`"
#         schedule = "(Full schedule: https://pretalx.com/juliacon2021/schedule)"
#         reply(c, m, not_now * today * "\n\n" * schedule)
#     else
#         reply(c, m, JuliaCon.now(output=:text))
#     end
#     return nothing
# end

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

function jc_today(c::Client, m::Message; day = today())
    if JuliaCon.get_today(now = day) === nothing
        not_today = "There is no JuliaCon program today!"
        @info not_today
        schedule = "(Full schedule: https://pretalx.com/juliacon2021/schedule)"
        reply(c, m, not_today * "\n\n" * schedule)
    else
        strings = Vector{String}()
        aux = JuliaCon.today(now = day, output = :text)
        tables, legend = aux[1:end-1], aux[end]
        for t in tables, str in split_pretty_table(t)
            push!(strings, str)
        end
        push!(strings, legend)
        foreach(s -> reply(c, m, s), strings)
    end
    return nothing
end
