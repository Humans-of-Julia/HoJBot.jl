"""
    TypedFunction{T}

A callable object that takes an argument of type `T`. This is useful for limiting
dispatch to a function that requires a specific argument type.

See other example at https://github.com/PacktPublishing/Hands-on-Design-Patterns-and-Best-Practices-with-Julia/blob/b20ad0fdfe73b05091fce6e52ca72f03ee0746e2/Chapter12/2_variance.jl#L283
"""
struct TypedFunction{T}
    func::Function
end

# Dispatcher
(tf::TypedFunction{T})(arg::T; kwargs...) where {T} = tf.func(arg; kwargs...)
