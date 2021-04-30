const DISCOURSE_DOMAIN = "https://discourse.julialang.org"

"""
    DiscoursePost

A Discourse post is unique identified by an `id` and a `slug`.
"""
struct DiscoursePost
    id::Int
    slug::String
end

"""
    url(p::DiscoursePost)

Return the URL for the specified post.
"""
url(p::DiscoursePost) = "$DISCOURSE_DOMAIN/t/$(p.slug)/$(p.id)"

struct DiscourseData
    posts::Vector{DiscoursePost}
    index::Int
end

function Base.show(io::IO, d::DiscourseData)
    print(io, "DiscourseData[index=", d.index, ", posts=", length(d.posts), "]")
end

"""
    current(r::DiscourseData)

Return the current post.
"""
current(r::DiscourseData) = r.posts[r.index]

Base.length(r::DiscourseData) = length(r.posts)

function next(r::DiscourseData)
    new_index = r.index + 1
    return DiscourseData(r.posts, new_index > length(r) ? 1 : new_index)
end

function previous(r::DiscourseData)
    new_index = r.index - 1
    return DiscourseData(r.posts, new_index == 0 ? length(r) : new_index)
end

"""
    message(r::DiscourseData)

Return a formatted string with the current post.
"""
function message(r::DiscourseData)
    link = url(current(r))
    total = length(r)
    return "$(r.index)/$(total): $link"
end

# JSON3 struct bindings
StructTypes.StructType(::Type{HoJBot.DiscourseData}) = StructTypes.Struct()
StructTypes.StructType(::Type{HoJBot.DiscoursePost}) = StructTypes.Struct()

"""
Construct a new `DiscourseData` based upon JSON3 data returned from a search.
"""
function DiscourseData(json::JSON3.Array, make_post::Function)
    list = unique(make_post(t) for t in json)
    return DiscourseData(list, 1)
end
