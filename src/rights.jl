abstract type CollectionOfRights end

struct BotAdmin <: CollectionOfRights end
struct OrdinaryUser <: CollectionOfRights end
abstract type GranularRight <: CollectionOfRights end


struct Functionality{symb} end

allowedto(user::User, func::Val{T}) where T = allowedto(user, Functionality{T})

function allowedto(user::User, func::Functionality)
    return allows(rights(user), requirements(func))
end

function allows(role::CollectionOfRights, right::GranularRight)::Bool
    return role isa BotAdmin
end

function allows(role::GranularRight, right::GranularRight)::Bool
    return role==right
end

function requirement(func::Functionality)::AbstractRight end

function rights(u::User)::AbstractVector{CollectionOfRights}
    u.id in [198170782285692928, 268802670553202699, 223188378235961347] ? BotAdmin() : OrdinaryUser()
end
