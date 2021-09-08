const CITY_ALIASES = Dict(
    "LA" => "America/Los_Angeles",
    "NY" => "America/New_York",
    "Rio" => "America/Fortaleza",
    "Brussels" => "Europe/Brussels",
)

const DATE_TIME_PATTERNS = (
    dateformat"yyyy-mm-dd HH:MM",
    dateformat"yyyy-mm-dd HH:MMp", # AM/PM
)

function commander(c::Client, m::Message, ::Val{:time_zone})
    # @info "time_zone_commander called"
    # @info "Message content" m.content m.author.username m.author.discriminator
    startswith(m.content, COMMAND_PREFIX * "tz") || return nothing
    regex = Regex(COMMAND_PREFIX * raw"tz (help|convert|aliases) *(.*)$")
    matches = match(regex, m.content)
    if matches === nothing || matches.captures[1] == "help"
        help_commander(c, m, :time_zone)
        return nothing
    elseif matches.captures[1] == "aliases"
        help_time_zone_aliases(c, m)
    elseif matches.captures[1] == "convert"
        handle_time_zone_conversion(c, m, matches.captures[2])
    else
        @error "Bug: unreachable reached! :-)"
    end
end

function help_commander(c::Client, m::Message, ::Val{:time_zone})
    # @info "Sending help for message" m.id m.author
    return reply(
        c,
        m,
        """
        How to use the `tz` command:
        ```
        tz help
        tz convert <date> <time> <alias/timezone>
        tz aliases
        ```
        Some examples are listed below.
        You can use an alias or any official time zone names from https://en.wikipedia.org/wiki/List_of_tz_database_time_zones:
        ```
        2021-03-21 15:00 NY
        2021-03-21 01:00AM Rio
        2021-03-21 09:00PM America/Los_Angeles
        ```
        """,
    )
end

function help_time_zone_aliases(c::Client, m::Message)
    # @info "Sending aliases for message" m.id m.author
    aliases = join(sort(["$(rpad(k, 12)) => $v" for (k, v) in CITY_ALIASES]), "\n")
    return reply(
        c,
        m,
        """
        tz command's time zone aliases are:
        ```
        $aliases
        ```
        """,
    )
end

function handle_time_zone_conversion(c::Client, m::Message, dts::AbstractString)
    try
        zdt = parse_date_time_spec(dts)
        converted_times = convert_time(zdt)
        output = join([ct.display for ct in converted_times], "\n")
        reply(
            c,
            m,
            """
            Alright, the local time are listed as follows:
            ```
            $output
            ```
            """,
        )
    catch ex
        @show ex
        reply(c, m, "Sorry, I don't understand this format: `$dts`")
    end
end

# Examples:
# 2021-03-21 16:00 America/Los_Angeles
# 2021-03-21 9:00PM NY
function parse_date_time_spec(dts::AbstractString)
    tokens = split_date_time_tokens(dts)
    vanilla_dt = parse_date_time(tokens.datetime)
    timezone = parse_time_zone(tokens.city)
    return ZonedDateTime(vanilla_dt, timezone)
end

function split_date_time_tokens(dts::AbstractString)
    tokens = split(dts, " ")
    length(tokens) === 3 || error("Bad date time spec: $dts")
    return (datetime=join(tokens[1:2], " "), city=tokens[3])
end

function parse_date_time(dt::AbstractString)
    for pattern in DATE_TIME_PATTERNS
        local datetime
        try
            return DateTime(dt, pattern)
        catch ex
        end
    end
    return error("Unable to parse date/time: $dt")
end

function parse_time_zone(city::AbstractString)
    city_time_zone = get(CITY_ALIASES, city, city)
    return TimeZone(city_time_zone)
end

function convert_time(t::ZonedDateTime)
    display_format = "yyyy-mm-dd II:MMp"
    return [
        let
            datetime = astimezone(t, TimeZone(city))
            display = Dates.format(datetime, display_format) * " $alias"
            (; alias, datetime, display)
        end for (alias, city) in CITY_ALIASES
    ]
end
