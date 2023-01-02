using Test
using HoJBot: mod_make_regex, mod_check_message

# initialization bad word list since it's lazy
HoJBot.mod_init()

@testset "mod" begin
    function test_matches(regex, strs, expected)
        for i in 1:length(strs)
            @test (match(regex, strs[i]) !== nothing) == expected[i]
        end
    end

    # regular word
    let regex = mod_make_regex("bad")
        strs = ["bad", "notbad", "badness"]
        expected = [true, false, false]
        test_matches(regex, strs, expected)
    end

    # having symbols in the match word
    let regex = mod_make_regex("b.a.d")
        strs = ["b.a.d", "b1a2d"]
        expected = [true, false]
        test_matches(regex, strs, expected)
    end

    @test isempty(mod_check_message("this is good")) == true
    @test isempty(mod_check_message("this is ass")) == false
    @test isempty(mod_check_message("this is ||ass||")) == true
    @test isempty(mod_check_message("this is ass ||ass||")) == false
    @test isempty(mod_check_message("this is ok ||ass")) == true
end
