@enum WordClass begin
    Bad
    Questionable
    Overridden
end
struct BadWord
    class::WordClass
    word::String
end

const WordClassStrings = Dict(
    Bad => "Bad",
    Questionable => "Questionable",
    Overridden => "Overridden",
)

function Base.show(io::IO, w::BadWord)
    print(io, WordClassStrings[w.class], "(", w.word, ")")
end
