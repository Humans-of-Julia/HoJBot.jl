const MOD_REPORT_CHANNEL_NAME = "mod-report"
const MOD_REPORT_CHANNEL = Ref{DiscordChannel}()

const MOD_BAD_WORDS = Set{BadWord}()
const MOD_BAD_WORD_REGEXES = Dict{BadWord,Regex}()

function handler(c::Client, e::Union{MessageCreate,MessageUpdate}, ::Val{:mod})
    if ismissing(e.message.content)
        return nothing # Possible e.g. only embed is updated by Discord (flipping discourse)
    end

    if e.message.author.id == c.state.user.id
        return nothing # No need to check if the message came from the bot itself
    end

    mod_report_channel = mod_get_report_channel(c, e.message.guild_id)
    if mod_report_channel === nothing
        return nothing # config error; nothing we can do about...
    end
    if e.message.channel_id == mod_report_channel.id
        return nothing # Do not moderate the mod channel itself
    end

    mod_init() # lazy initialization
    result = mod_check_message(e.message.content)
    if !isempty(result)
        user_id = e.message.author.id
        report_message_id = e.message.id
        # Censor message
        new_content = mod_censor_message(e.message.content, result)
        if new_content != e.message.content
            delete_message(c, e.message.channel_id, e.message.id)
            censored_message = @discord create_message(
                c, e.message.channel_id; content="<@!$(user_id)> said: $new_content"
            )
            report_message_id = censored_message.id
        end
        # Update the mod-report channel
        report = mod_report(
            user_id,
            e.message.content,
            result,
            report_message_id,
            e.message.channel_id,
            e.message.guild_id,
        )
        if mod_report_channel !== nothing
            create_message(c, mod_report_channel.id; content=report)
        end
    end
    return nothing
end

"Get the mod-report channel."
function mod_get_report_channel(c::Client, guild_id::Integer)
    if !isassigned(MOD_REPORT_CHANNEL)
        channels = @discord get_guild_channels(c, guild_id)
        channel = filter(c -> c.name == MOD_REPORT_CHANNEL_NAME, channels)
        if length(channel) == 1
            MOD_REPORT_CHANNEL[] = channel[1]
            return MOD_REPORT_CHANNEL[]
        else
            @error "Unable to find mod report channel: $MOD_REPORT_CHANNEL_NAME"
            return nothing
        end
    end
    return MOD_REPORT_CHANNEL[]
end

"Initialize mod function e.g. read bad words list."
function mod_init(; force=false)
    if force
        empty!(MOD_BAD_WORDS)
    end
    if isempty(MOD_BAD_WORDS)
        bad_words_file = joinpath(@__DIR__, "..", "..", "config", "mod", "bad-words.txt")
        bad_words = readlines(bad_words_file)
        for word in bad_words
            if startswith(word, '?')
                mod_add_bad_word(BadWord(Questionable, word[2:end]))
            elseif startswith(word, '-')
                mod_add_bad_word(BadWord(Overridden, word[2:end]))
            else
                mod_add_bad_word(BadWord(Bad, word))
            end
        end
    end
end

"Create a regex that matches a word."
function mod_make_regex(word::AbstractString)
    return Regex(string(
        "\\b",           # any word boundary
        "(",
        "\\Q",           # parse symbols as-is with \Q and \E marker
        word,
        "\\E",
        ")",
        "\\b",           # any word boundary
    ), "i")
end

"Add a new bad word to the global list."
function mod_add_bad_word(w::BadWord)
    try
        MOD_BAD_WORD_REGEXES[w] = mod_make_regex(w.word)
        push!(MOD_BAD_WORDS, w)
    catch ex
        @warn "Cannot compile regex for word" w.word regex_str
    end
end

"Return true if `content` contains `word` considering word boundaries."
function mod_contains(content::AbstractString, w::BadWord)
    regex = MOD_BAD_WORD_REGEXES[w]
    return match(regex, content) !== nothing
end

"""
    mod_check_message(content::AbstractString)

Check the message content and return a set
of identified bad words. An empty set is returned if
nothing is found.
"""
function mod_check_message(content::AbstractString)
    # split by spoiler marker
    # after this, every even-number token is within the spoiler markers
    tokens = split(content, "||")

    result = Set{BadWord}()
    for (i, t) in enumerate(tokens)
        if isodd(i)
            bad_word_set = mod_check(t)
            union!(result, bad_word_set)
        end
    end
    return result
end

"""
    mod_check(content::AbstractString)

Check the content against a profanity set of words.
"""
function mod_check(content::AbstractString)
    return Set{BadWord}(w for w in MOD_BAD_WORDS if mod_contains(content, w))
end

"""
    mod_report

Return a string about the issue that will be sent to the mod-report channel.
"""
function mod_report(
    user_id::Integer,
    content::AbstractString,
    bad_words::AbstractSet{BadWord},
    message_id::Integer,
    channel_id::Integer,
    guild_id::Integer,
)
    str = join([w.word for w in bad_words], ", ")
    badness = mod_badness(bad_words)
    return "$badness message from <@!$user_id> with `$str`: $(content)\n" *
           "Ref: https://discord.com/channels/$guild_id/$channel_id/$message_id"
end

"""
    mod_badness(bad_words::AbstractSet{BadWord})

Return a string that describe how bad the message is based
upon the set of bad words already found from the message.
"""
function mod_badness(bad_words::AbstractSet{BadWord})
    return if any(x -> x.class === Bad, bad_words)
        "Bad"
    elseif any(x -> x.class === Questionable, bad_words)
        "Questionable"
    elseif any(x -> x.class === Overridden, bad_words)
        "Overridden"
    else
        "Unknown"
    end
end

"""
    mod_censor_message(content, bad_words)

Returned a censored string for the message. For example,
bad words may be hidden using spoiler tags. Text that are within
Discord spoiler markers are ignored. Only `bad_words` are
considered. See `mod_check_message`[@ref] about how to gather
the list.
"""
function mod_censor_message(content::AbstractString, bad_words::AbstractSet{BadWord})
    original_content = content

    tokens = split(content, "||")
    buf = IOBuffer()
    for (i, token) in enumerate(tokens)
        if isodd(i)
            token = mod_censor(token, bad_words)
        else
            token = "||" * token * "||"
        end
        print(buf, token)
    end
    content = String(take!(buf))

    @info "Censored: original=$original_content new=$content"
    return content
end

"""
    mod_censor(content, bad_words)

If the `content` contains any bad word from the list, then it is
hidden by Discord spoiler markers. See `mod_check_message`[@ref]
about how to gather the list.
"""
function mod_censor(content::AbstractString, bad_words::AbstractSet{BadWord})
    for w in bad_words
        regex = MOD_BAD_WORD_REGEXES[w]
        if w.class in (Bad, Questionable)
            content = replace(content, regex => s"||\1||")
        end
    end
    return content
end
