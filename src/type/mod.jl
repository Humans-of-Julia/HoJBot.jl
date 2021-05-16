abstract type AbstractBadWord end

struct BadWord <: AbstractBadWord
    word::String
end

struct QuestionableWord <: AbstractBadWord
    word::String
end

struct OverriddenWord <: AbstractBadWord
    word::String
end

function Base.show(io::IO, w::AbstractBadWord)
    print(io, w.word)
end
