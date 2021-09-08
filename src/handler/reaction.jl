# Reactors
#
# On every MessageCreate event, we can apply a reaction to the message.
# The code below can be easily extends by defining a subtype of
# `AbstractReactor` and implement the respective interface methods.

# ----------------------------------------------------------------------
# Interface
# ----------------------------------------------------------------------

abstract type AbstractReactor end

function reactions(r::AbstractReactor, m::Message)::Vector{Char} end

const NO_REACTION = Char[]

# ----------------------------------------------------------------------
# Reactors
# ----------------------------------------------------------------------

const REACT_WORDS = Dict(
    :happy => [
        "happy",
        "nice",
        "great",
        "awesome",
        "cheers",
        "yay",
        "congrat",
        "congrats",
        "congratulations",
        "it helped",
        "it helps",
        "appreciate",
        "appreciated",
        "noice",
        "thank",
        "thanks",
    ],
    :disappointed => ["disappointed", "unhappy", "sad", "aw shucks", "yeow"],
    :excited => [
        "excited",
        "fantastic",
        "fabulous",
        "wonderful",
        "looking forward to",
        "love",
        "learned",
        "saved me",
        "beautiful",
    ],
    :goodbye => ["cya", "bye", "goodbye", "ciao", "adios", "brb"],
    :dog => ["dog", "dogs", "doggie", "shiba", "corgi", "chihuahua", "retriever"],
    :cat => ["cat", "cats", "feline", "kitten", "kittens"],
    :snake => ["snake", "snakes", "rattle", "python", "pythons"],
    :crab => ["crab", "crabs", "rust"],
)

function contains_any(s::AbstractString, words::AbstractVector{String})
    is_thing(x) = x !== nothing
    regexes = [Regex("\\b" * w * "\\b") for w in words]
    matches = match.(regexes, lowercase(s))
    return any(is_thing(x) for x in matches)
end

struct HappyReactor <: AbstractReactor end

function reactions(::HappyReactor, m::Message)
    if contains_any(m.content, REACT_WORDS[:happy]) &&
       !contains_any(m.content, REACT_WORDS[:disappointed])
        return ['😄']
    end
    return NO_REACTION
end

struct DisappointedReactor <: AbstractReactor end

function reactions(::DisappointedReactor, m::Message)
    if contains_any(m.content, REACT_WORDS[:disappointed]) &&
       !contains_any(m.content, REACT_WORDS[:happy]) &&
       !contains_any(m.content, REACT_WORDS[:excited])
        return ['😞']
    end
    return NO_REACTION
end

struct ExcitedReactor <: AbstractReactor end

function reactions(::ExcitedReactor, m::Message)
    if contains_any(m.content, REACT_WORDS[:excited]) &&
       !contains_any(m.content, REACT_WORDS[:disappointed])
        return ['🤩']
    end
    return NO_REACTION
end

struct GoodbyeReactor <: AbstractReactor end

function reactions(::GoodbyeReactor, m::Message)
    if contains_any(m.content, REACT_WORDS[:goodbye])
        return ['👋']
    end
    return NO_REACTION
end

struct AnimalReactor <: AbstractReactor end

function reactions(::AnimalReactor, m::Message)
    result = Char[]
    if contains_any(m.content, REACT_WORDS[:dog])
        push!(result, '🐕')
    end
    if contains_any(m.content, REACT_WORDS[:cat])
        push!(result, '🐈')
    end
    if contains_any(m.content, REACT_WORDS[:snake])
        push!(result, '🐍')
    end
    if contains_any(m.content, REACT_WORDS[:crab])
        push!(result, '🦀')
    end
    return result
end

# ----------------------------------------------------------------------
# Main logic
# ----------------------------------------------------------------------

const REACTORS = AbstractReactor[
    HappyReactor(),
    DisappointedReactor(),
    ExcitedReactor(),
    GoodbyeReactor(),
    AnimalReactor(),
]

function handler(c::Client, e::MessageCreate, ::Val{:reaction})
    # @info "react_handler called"
    # @info "Received message" e.message.channel_id e.message.id e.message.content
    username = e.message.author.username
    discriminator = e.message.author.discriminator
    !get_opt!(username, discriminator, :reaction) && return nothing
    for reactor in REACTORS
        rs = reactions(reactor, e.message)
        foreach(rs) do emoji
            create(c, Reaction, e.message, emoji)
        end
    end
    return nothing
end
