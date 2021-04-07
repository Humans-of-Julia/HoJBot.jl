using HoJBot:
    replace_newlines,
    is_real_user, is_bot,
    flipper, previous, next
using Discord: User

@testset "utilities" begin

    let
        @test replace_newlines("a\nb") == "a b"
        @test replace_newlines("a\nb\n") == "a b "
        @test replace_newlines("a\nb \n\n") == "a b   "
    end

    let user = User(; id = 1, bot = false), bot = User(; id = 2, bot = true)
        @test is_real_user(user) === true
        @test is_real_user(bot) === false
        @test is_bot(user) === false
        @test is_bot(bot) === true
    end

    # Tainted module here but it's OK since it's just a test
    HoJBot.previous(x::Int) = x - 1
    HoJBot.next(x::Int) = x + 1
    @test flipper(previous, Int)(1) == 0
    @test flipper(next, Int)(1) == 2

end
