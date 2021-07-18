module Command

    using Discord: Snowflake

    queue, q
        (Val{:q}, Val{:join!}, queuename::String)#`q join! <queue>` adds user to queue
        (Val{:q}, Val{:leave!}, queuename::String)# `q leave! <queue>` removes user from queue
        (Val{:q}, Val{:list}, queuename::String)# `q list <queue>` lists the specified queue
        (Val{:q}, Val{:position})# `q position` shows the current position in every queue
        (Val{:q}, Val{:pop!}, queuename::String)# `q pop! <name>` removes the user with the first position from the queue
        (Val{:q}, Val{:create!}, queuename::String, role::Snowflake)# `q create! <name> <role>` creates a new queue that is managed by <role>
        (Val{:q}, Val{:channel!}, queuename::String)# `q channel! <queue>` set the channel that lists the queues
        (Val{:q}, Val{:remove!}, queuename::String)# `q remove! <name>` removes an existing queue
        (Val{:q}, Val{:help})# `q help` returns this help

    abstract type AbstractFragment end
    struct FragmentContainer <: AbstractFragment
        fragment::AbstractFragment
        followups::Vector{AbstractFragment}
    end
    FragmentContainer(fragment::AbstractFragment) = FragmentContainer(fragment, AbstractFragment[])
    
    function FragmentContainer(fragment::FragmentContainer, followups::Vector{AbstractFragment})
        @error "can't wrap FragmentContainers"
    end

    function Base.push!(fragment::FragmentContainer, followup::AbstractFragment)
        push!(fragment.followups, followup)
        return fragment
    end

    struct RootFragment <: AbstractFragment end

    struct ConstantFragment <: AbstractFragment
        constant::String
    end

    struct ArgumentFragment{T, F} <: AbstractFragment
        name::String
        parser::F
    end
    ArgumentFragment{T}(parser, name::String) where T = ArgumentFragment{T, typeof(parser)}(name, parser)
    ArgumentFragment{T}(name::String, parser) where T = ArgumentFragment{T, typeof(parser)}(name, parser)
    ArgumentFragment{T}(name::String) where T = ArgumentFragment{T, Base.Fix1}(name, Base.Fix1(convert, T))


    struct ApplyFragment <: AbstractFragment
        toapply
    end

    function combine(fragments::AbstractFragment...)
        length(fragments) == 0 && return nothing
        base = fragments[1]
        if !(base isa FragmentContainer)
            base = FragmentContainer(base)
        end
        for frag in fragments[2:end]
            
        end
    end

    function initialize_queue_fragment()
        arg_queuename = ArgumentFragment{String}("queuename")
        arg_role = ArgumentFragment{Snowflake}("role")
        
        root = RootFragment()
        q = combine(root, ConstantFragment("q"))
        create = combine(q, ConstantFragment("create!"))
        join = ConstantFragment("join!")

    end

end
