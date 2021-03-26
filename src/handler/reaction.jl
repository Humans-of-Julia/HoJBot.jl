# Reactors
#
# On every MessageCreate event, we can apply a reaction to the message.
# The code below can be easily extends by defining a subtype of
# `AbstractReactor` and implement the respective interface methods.

# ----------------------------------------------------------------------
# Interface
# ----------------------------------------------------------------------

abstract type AbstractReactor end

function reactions(r::AbstractReactor, m::Message)::Vector{Char}
end

const NO_REACTION = Char[]

# ----------------------------------------------------------------------
# Reactors
# ----------------------------------------------------------------------

struct HappyReactor <: AbstractReactor end

function reactions(::HappyReactor, m::Message)
    words = ["happy", "nice", "great", "awesome", "cheers", "yay", "yayy", "congratulations", "it helped", "appriciate", "noice", "thanks"]
    if any(occursin.(words, m.content))
        return ['😄']
    end
    return NO_REACTION
end

struct DisappointedReactor <: AbstractReactor end

function reactions(::DisappointedReactor, m::Message)
    words = ["disappointed", "unhappy"]
    if any(occursin.(words, m.content))
        return ['😞']
    end
    return NO_REACTION
end

struct ExcitedReactor <: AbstractReactor end

function reactions(::ExcitedReactor, m::Message)
    words = ["excited", "fantastic", "fabulous", "wonderful", "looking forward to", "love", "learn", "julia", "saved me"]
    if any(occursin.(words, m.content))
        return ['🤩']
    end
    return NO_REACTION
end

# ----------------------------------------------------------------------
# Main logic
# ----------------------------------------------------------------------

const REACTORS = AbstractReactor[
    HappyReactor(),
    DisappointedReactor(),
    ExcitedReactor(),
]

function react_handler(c::Client, e::MessageCreate)
    # @info "react_handler called"
    # @info "Received message" e.message.channel_id e.message.id e.message.content
    for reactor in REACTORS
        rs = reactions(reactor, e.message)
        foreach(rs) do emoji
            create(c, Reaction, e.message, emoji)
        end
    end
end
