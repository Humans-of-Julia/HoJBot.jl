function commander(c::Client, m::Message, ::Val{:refresh})
    @assert startswith(m.content, COMMAND_PREFIX * "refresh")
    hasprivilege(m.user, Val(:refresh)) || return
    parts = split(m.content[length(COMMAND_PREFIX)+1:end])
    idx = findfirst(x->startswith(x,"test"), parts)
    if idx !== nothing
        tester = parts[idx][5:end]
        if startswith(tester, "pr")
            id = parts[idx+1]
            tryparse(Int, id) === nothing && return nothing
            branch = "branch_"*id
            run(`git fetch origin pull/$id/head:$branch`)
        elseif startswith(tester, "branch")
            branch = parts[idx+1]
        else
            reply(c, m, "test$tester is an unknown argument")
            return nothing
        end
        run(`git switch $branch`)
    end
    if any(==("needsrestart"), parts)
        touch("SHUTDOWN")
    else
        #Revise.revise()
        @eval HoJBot includejlfiles("command/")
        @eval HoJBot includejlfiles("handler/")
    end
    return nothing
end

function help_commander(c::Client, m::Message, ::Val{:refresh})
    reply(c, m, """
        How to use the `refresh` command:
        ```
        refresh help
        refresh [cmd arg] [needsrestart]
        ```
        `cmd` can be either of `testpr` and `testbranch`. Arg has a different meaning correspondingly:
            testpr: arg is of the format `id` where id is the pull request id as on github (creates a local branch: "branch_\$id")
            testbranch: arg is of the format `branch` where branch is the (remote) branch to be switched to

        when `needsrestart` is passed, the bot will restart once the corresponding operation has been completed. Otherwise it'll just reinclude the files in "commands/" and "handlers/"
        """)
end
