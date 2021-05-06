const MOD_REPORT_CHANNEL_NAME = "mod-report"
const MOD_REPORT_CHANNEL = Ref{DiscordChannel}()
const BAD_WORDS = Vector{String}()

function handler(c::Client, e::MessageCreate, ::Val{:mod})
    # @info "mod handler: $(e.message.content)"

    mod_report_channel = mod_get_report_channel(c, e.message.guild_id)
    if mod_report_channel === nothing
        return # config error; nothing we can do about...
    end
    if e.message.channel_id == mod_report_channel.id
        return # Do not moderate the mod channel itself
    end

    mod_init() # lazy initialization
    result, word_involed = mod_check(e.message.content)
    if result != :good
        username = e.message.author.username
        report = mod_report(username, e.message.content, result, word_involed)
        if mod_report_channel !== nothing
            create(c, Message, mod_report_channel; content = report)
        end
    end
    return nothing
end

"Get the mod-report channel."
function mod_get_report_channel(c::Client, guild_id::UInt64)
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
function mod_init()
    if isempty(BAD_WORDS)
        bad_words_file = joinpath(@__DIR__, "..", "..", "config", "mod", "bad-words.txt")
        bad_words = readlines(bad_words_file)
        append!(BAD_WORDS, bad_words)
    end
end

"Returns true if the word string is questionably bad."
mod_is_questionable(w::AbstractString) = startswith(w, "?")

"Return true if the string contains any non-alpha/numeric character."
mod_contains_symbols(w::AbstractString) = occursin(r"[^0-9a-zA-Z]", w)

"Return true if `content` contains `word` considering word boundaries."
function mod_contains(content::AbstractString, word::AbstractString)
    content = lowercase(content)
    try
        regex = Regex("\\b" * word * "\\b")
        return match(regex, content) !== nothing
    catch ex
        @error "cannot compile: $word"
        Base.showerror(stdout, ex)
        return false
    end
end

"Return true if `word` appears anywhere in `content` without considering word boundaries."
function mod_contains_exactly(content::AbstractString, word::AbstractString)
    content = lowercase(content)
    return occursin(word, content)
end

"""
    mod_check(content::AbstractString)

Check the content against a profanity set of words. Returns status as
one of the symbols - `:good`, `:bad`, or `:questionable`.
"""
function mod_check(content::AbstractString)
    for bad_word in BAD_WORDS
        questionable = mod_is_questionable(bad_word)
        word = questionable ? bad_word[2:end] : bad_word
        if (mod_contains_symbols(word) && mod_contains_exactly(content, word)) ||
                mod_contains(content, word)
            @info "Bad word `$word` detected: $content"
            return questionable ? (:questionable, word) : (:bad, word)
        end
    end
    return (:good, "")
end

function mod_report(
    username::AbstractString,
    content::AbstractString,
    result::Symbol,
    word_involved::AbstractString,
)
    return if result == :bad
        "Bad message from $username with `$word_involved`: $(content)"
    elseif result == :questionable
        "Questionable message from $username with `$word_involved`: $(content)"
    else # should never happen
        "Unclear how bad is the message from $username with `$word_involved`: $(content)"
    end
end
