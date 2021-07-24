const Functionality = Val
const PATHBASE = "data/permissions/"

has_access(guid::Snowflake, member::Member, task::Functionality) = has_access(guid, member.roles, task)

function has_access(guid::Snowflake, roles::Vector{Snowflake}, ::Functionality{Task}) where Task
    guildperms = PERMISSIONS[guid]
    return !isdisjoint(guildperms[Task], roles)
end

function grant!(guid::Snowflake, role::Snowflake, ::Functionality{Task}) where Task
    guildperms = PERMISSIONS[guid]
    push!(guildperms[Task], role)
    save(guid, guildperms)
end

function revoke!(guid::Snowflake, role::Snowflake, ::Functionality{Task}) where Task
    guildperms = PERMISSIONS[guid]
    delete!(guildperms[Task], role)
    save(guid, guildperms)
end

"""GuildID->(Functionality->[permitted roles])"""
const PERMISSIONS = Dict{Snowflake,Dict{Symbol,Set{Snowflake}}}()


function load()
    isdir(PATHBASE) || return
    for file in readdir(PATHBASE)
        guid = parse(Snowflake, file)
        load(guid, checkpath=false)
    end
end

function load(guid::Snowflake, dir=PATHBASE; checkpath=true)
    checkpath && isdir(dirname(file)) || return
    open(joinpath(dir, string(guid))) do io
        fguid = read(io, Snowflake)
        if fguid != guid
            @info "file conflict, tried to load $guid but got $fguid"
            return
        end
        while !eof(io)
            lensym = read(io, UInt8)
            lenroles = read(io, UInt8)
            sym = Symbol(read(io, lensym))
            roles = Set(reinterpret(Snowflake, read(io, lenroles)))
            PERMISSIONS[sym] = roles
        end
    end
end

function save()
    ensurepath!(PATHBASE)
    for (k,v) in pairs(PERMISSIONS)
        save(k, v, ensurepath=false)
    end
end

function save(guid::Snowflake,
    permissions::Dict{Symbol,Set{Snowflake}}=PERMISSIONS[guid]; ensurepath=true)
    ensurepath && ensurepath!(PATHBASE)
    open(joinpath(dir, string(guid))) do io
        fguid = write(io, guid)
        for (k,v) in pairs(permissions)
            write(io, UInt8(sizeof(k)), UInt8(sizeof(v)))
            write(io, k, v...)
        end
    end
end
