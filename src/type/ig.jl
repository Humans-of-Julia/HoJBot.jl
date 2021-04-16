mutable struct IgHolding
    symbol::String
    shares::Float64
    date::Date
    purchase_price::Float64
end

mutable struct IgPortfolio
    cash::Float64
    holdings::Vector{IgHolding}
end

struct IgUserError
    message::String
end

struct IgSystemError
    message::String
end

abstract type AbstractPortfolioOutputView end
struct PrettyView <: AbstractPortfolioOutputView end
struct SimpleView <: AbstractPortfolioOutputView end

# JSON3 struct bindings
StructTypes.StructType(::Type{IgHolding}) = StructTypes.Struct()
StructTypes.StructType(::Type{IgPortfolio}) = StructTypes.Struct()
