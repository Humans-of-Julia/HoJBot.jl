using HoJBot
using Test

@testset "HoJBot.jl" begin
    include("test_utils.jl")
    include("test_discourse.jl")
    include("test_ig.jl")
end
