using HoJBot:
    DiscourseData, DiscoursePost,
    discourse_run_query, discourse_load, discourse_save,
    current, message, next, previous

import JSON3

@testset "discourse" begin

    json = discourse_run_query("search.json", "pluto")

    let
        @test json isa JSON3.Object
        @test hasproperty(json, :topics)
        @test length(json.topics) > 0
        @test hasproperty(json.topics[1], :id)
        @test hasproperty(json.topics[1], :slug)
    end

    let data = DiscourseData(json)
        @test length(data) == length(json.topics)
        @test 1 <= data.index <= length(data)
        @test current(data) isa DiscoursePost

        let index = data.index
            # cycle once using `next`
            for i in 1:length(data)
                data = next(data)
            end
            @test data.index === index

            # cycle once using `pevious`
            for i in 1:length(data)
                data = previous(data)
            end
            @test data.index === index
        end

        let msg = message(data)
            @test length(msg) > 0
            @test occursin("http", msg)
        end

        # load/save
        let
            id = UInt64(0)
            @test_nowarn discourse_save(id, data)
            loaded = @test_nowarn discourse_load(id)
            @test length(data) == length(loaded)
            @test data.index == loaded.index
            @test data.posts == loaded.posts
        end
    end
end
