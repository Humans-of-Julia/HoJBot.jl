module Overwrites

using Discord, JSON3, StructTypes
using JSON3: @check, realloc!

module StrutTypes

using StructTypes
supertype(x::Type{T}) where T = nothing
supertype(x::T) where T = supertype(T)

function __init__()
    Base.eval(StructTypes, :(supertype = $supertype))
end

end

function Discord.reply(c::Client, m::Message, content::AbstractString; at::Bool=false, kwargs...)
    at && !ismissing(m.author) && (content = string(m.author, " ", content))
    return create_message(c, m.channel_id; content=content, message_reference=(;message_id=m.id), kwargs...)
end

function Discord.reply(
    c::Client,
    m::Message,
    embed::Union{AbstractDict, NamedTuple, Embed};
    at::Bool=false, kwargs...
)
    return if at && !ismissing(m.author)
        create_message(c, m.channel_id; content=string(m.author), embed=embed, message_reference=(;message_id=m.id), kwargs...)
    else
        create_message(c, m.channel_id; embed=embed, message_reference=(;message_id=m.id), kwargs...)
    end
end

function JSON3.write(::StructTypes.DictType, buf, pos, len, x::T; kw...) where {T}
    JSON3.@writechar '{'
    pairs = StructTypes.keyvaluepairs(x)

    next = iterate(pairs)
    while next !== nothing
        (k, v), state = next

        buf, pos, len = JSON3.write(StructTypes.StringType(), buf, pos, len, JSON3.write(k); kw...)
        JSON3.@writechar ':'
        buf, pos, len = JSON3.write(StructTypes.StructType(v), buf, pos, len, v; kw...)

        next = iterate(pairs, state)
        next === nothing || JSON3.@writechar ','
    end
    JSON3.@writechar '}'
    return buf, pos, len
end

@inline function JSON3.write(::Union{StructTypes.Struct, StructTypes.Mutable}, buf, pos, len, x::T; kw...) where {T}
    JSON3.@writechar '{'
    suptyp = supertype(T)

    c = JSON3.WriteClosure(buf, pos, len, false, values(kw))
    if suptyp!==nothing && StructTypes.StructType(suptyp) isa StructTypes.AbstractType
        c(0, StructTypes.subtypekey(suptyp), Symbol, find_type_identifier(suptyp, T))
    end
    StructTypes.foreachfield(c, x)
    buf = c.buf
    pos = c.pos
    len = c.len
    JSON3.@writechar '}'
    return buf, pos, len
end

@inline find_type_identifier(suptyp::Type{S}, elemtyp::Type{T}) where {S,T} = findfirst(==(T), StructTypes.subtypes(S))

function StructTypes.constructfrom!(::StructTypes.DictType, target::AbstractDict{K,V}, source) where {K,V}
    for (k,v) in pairs(source)
        target[StructTypes.constructfrom(K, JSON3.read(string(k)))] = StructTypes.constructfrom(V, v)
    end
    return target
end
function StructTypes.constructfrom!(::StructTypes.ArrayType, target::AbstractArray{T}, source) where {T}
    eltype(source)==T && return append!(target, source)
    for e in source
        push!(target, StructTypes.constructfrom(T, e))
    end
    return target
end

end
