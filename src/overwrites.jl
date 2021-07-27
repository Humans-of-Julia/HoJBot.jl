module Overwrites

using Discord, JSON3, StructTypes
using JSON3: @check, realloc!

function Discord.reply(c::Client, m::Message, content::AbstractString; at::Bool=false)
    at && !ismissing(m.author) && (content = string(m.author, " ", content))
    return create_message(c, m.channel_id; content=content, message_reference=(;message_id=m.id))
end

function Discord.reply(
    c::Client,
    m::Message,
    embed::Union{AbstractDict, NamedTuple, Embed};
    at::Bool=false,
)
    return if at && !ismissing(m.author)
        create_message(c, m.channel_id; content=string(m.author), embed=embed, message_reference=(;message_id=m.id))
    else
        create_message(c, m.channel_id; embed=embed, message_reference=(;message_id=m.id))
    end
end

function JSON3.write(::StructTypes.DictType, buf, pos, len, x::T; kw...) where {T}
    JSON3.@writechar '{'
    pairs = StructTypes.keyvaluepairs(x)

    next = iterate(pairs)
    while next !== nothing
        (k, v), state = next

        buf, pos, len = JSON3.write(StructTypes.StructType(k), buf, pos, len, k; kw...)
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
    if StructTypes.StructType(suptyp) isa StructTypes.AbstractType
        buf, pos, len = JSON3.write(StructTypes.StringType(), buf, pos, len, StructTypes.subtypekey(suptyp); kw...)
        JSON3.@writechar ':'
        buf, pos, len = JSON3.write(StructTypes.StringType(), buf, pos, len, find_type_identifier(suptyp, T); kw...)
    end
    c = JSON3.WriteClosure(buf, pos, len, false, values(kw))
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
        target[StructTypes.constructfrom(K, k)] = StructTypes.constructfrom(V, v)
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
