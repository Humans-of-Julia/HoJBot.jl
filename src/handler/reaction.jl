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

# ----------------------------------------------------------------------
# Reactors
# ----------------------------------------------------------------------

struct HappyReactor <: AbstractReactor end

function reactions(::HappyReactor, m::Message)
    words = ["happy", "nice", "great"]
    if any(occursin.(words, m.content))
        return ['👍', '😄']
    end
    return Char[]
end

# ----------------------------------------------------------------------
# Main logic
# ----------------------------------------------------------------------

const REACTORS = AbstractReactor[
    HappyReactor(),
]

function react_handler(c::Client, e::MessageCreate)
    @info "react_handler called"
    @info "Received message" e.message.channel_id e.message.id e.message.content
    for reactor in REACTORS
        rs = reactions(reactor, e.message)
        foreach(rs) do emoji
            create(c, Reaction, e.message, emoji)
        end
    end
end
