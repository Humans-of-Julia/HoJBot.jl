using Test
using Dates
using Pretend
using DataFrames

using Discord:
    Client, DiscordChannel, Message, User

using HoJBot:
    IgHolding, IgPortfolio, IgUserError, PrettyView, SimpleView,
    current_date, discord_channel, discord_reply, discord_upload_file,
    recent_date_range, retrieve, retrieve_users, upload_file,
    ig_affirm_non_player, ig_affirm_player,
    ig_buy, ig_cash_entry, ig_chart, ig_count_shares, ig_execute,
    ig_file_path, ig_get_real_time_quote, ig_grouped_holdings, ig_hey,
    ig_historical_prices, ig_holdings_data_frame, ig_is_player,
    ig_load_all_portfolios, ig_load_portfolio, ig_mark_to_market!,
    ig_mark_to_market_portfolio, ig_ranking_table,
    ig_reformat_view!, ig_remove_game, ig_save_portfolio,
    ig_sell, ig_start_new_game, ig_value_all_portfolios, ig_view_table

Pretend.activate()

const USER_ID = UInt64(0)
const USER_ID2 = UInt64(1)
const USER_ID3 = UInt64(2)
const USER_NAME = "Joe"

function test_ig_cases(f, name)
    @testset "$name" begin
        try
            @test_nowarn ig_start_new_game(USER_ID)
            @test_nowarn ig_start_new_game(USER_ID2)
            f()
        finally
            @test_nowarn ig_remove_game(USER_ID)
            @test_nowarn ig_remove_game(USER_ID2)
        end
    end
end

function clean_ig_game_files()
    for id in (USER_ID, USER_ID2, USER_ID3)
        path = ig_file_path(id)
        isfile(path) && rm(path)
    end
end

# Mock functions
mock_ig_get_quote_100(symbol::AbstractString) = 100.0
mock_currrent_date() = Date(2021, 1, 11)
mock_reply(c::Client, m::Message, s::AbstractString) = nothing
mock_upload_file(c::Client, ch::DiscordChannel, filename::AbstractString; kwargs...) = nothing
mock_channel(c::Client, id::UInt64) = DiscordChannel(; id = 0x00, type = 0x00)

function mock_retrieve_users(c::Client, ids::Vector{UInt64})
    return Dict(id => User(; id=id, username="$id") for id in ids)
end

# Mock objects
mocked_client() = Client("hey")

@testset "Investment Game" begin

    # ensure everything is clean before we start
    clean_ig_game_files()

    test_ig_cases("Life cycle") do
        @test ig_is_player(USER_ID) == true
        @test ig_hey(USER_NAME, "wat") isa AbstractString
        @test_nowarn ig_affirm_player(USER_ID)
        @test_throws IgUserError ig_affirm_non_player(USER_ID)
    end

    test_ig_cases("Load/save") do
        # load
        pf = @test_nowarn ig_load_portfolio(USER_ID)
        @test pf.cash > 0
        @test isempty(pf.holdings)

        # save with holdings
        push!(pf.holdings, IgHolding("AAPL", 1, today(), 100))
        @test_nowarn ig_save_portfolio(USER_ID, pf)
        pf = @test_nowarn ig_load_portfolio(USER_ID)
        @test length(pf.holdings) == 1

        @test_nowarn ig_save_portfolio(USER_ID2, pf)
        pfs = ig_load_all_portfolios()
        @test length(pfs) >= 2   # two test pf's, plus whatever is there for others
        @test haskey(pfs, USER_ID)
        @test haskey(pfs, USER_ID2)
    end

    test_ig_cases("Buy/sell") do
        apply(ig_get_real_time_quote => mock_ig_get_quote_100) do
            # Buy something, portfolio should be updated
            executed_price = @test_nowarn ig_buy(USER_ID, "AAPL", 50)
            @test executed_price == 100.0

            # Load it again and check
            pf = ig_load_portfolio(USER_ID)
            @test length(pf.holdings) == 1
            @test pf.holdings[1].symbol == "AAPL"
            @test pf.holdings[1].shares == 50
            @test pf.cash == 1_000_000 - 50 * 100.0

            # Sell more than what you have
            @test_throws IgUserError ig_sell(USER_ID, "AAPL", 70)

            # Partial sell
            executed_price = @test_nowarn ig_sell(USER_ID, "AAPL", 30)
            @test executed_price == 100.0

            # What's left?
            pf = ig_load_portfolio(USER_ID)
            @test length(pf.holdings) == 1
            @test pf.holdings[1].symbol == "AAPL"
            @test pf.holdings[1].shares == 20

            # Sell completely
            ig_sell(USER_ID, "AAPL", 20)
            pf = ig_load_portfolio(USER_ID)
            @test length(pf.holdings) == 0
            @test pf.cash == 1_000_000

            # buy 3 lots relief
            ig_buy(USER_ID, "IBM", 50)
            ig_buy(USER_ID, "IBM", 50)
            ig_buy(USER_ID, "IBM", 50)
            ig_sell(USER_ID, "IBM", 80)
            pf = ig_load_portfolio(USER_ID)
            @test pf.cash == 1_000_000 - 70 * 100.0
            @test length(pf.holdings) == 2
            @test sort([h.shares for h in pf.holdings]) == [20, 50]
        end
    end

    test_ig_cases("Views") do
        # empty portfolio with pre-filled cash only
        df = @test_nowarn ig_mark_to_market_portfolio(USER_ID)
        @test nrow(df) == 1
        @test df.symbol[1] == "CASH:USD"

        # setup
        ig_buy(USER_ID, "AAPL", 100, 120)
        ig_buy(USER_ID, "IBM", 50, 130)
        ig_buy(USER_ID, "IBM", 50, 150)
        pf = ig_load_portfolio(USER_ID)

        # counting
        @test ig_count_shares(pf, "AAPL") == 100
        @test ig_count_shares(pf, "IBM") == 100

        # convert to holdings data frame
        df = @test_nowarn ig_holdings_data_frame(pf)
        @test df isa AbstractDataFrame
        @test sort(propertynames(df)) == sort([:symbol, :shares, :purchase_price, :purchase_date])

        # grouped with average pricing
        gdf = ig_grouped_holdings(df)
        @test hasproperty(gdf, :symbol) == true
        @test hasproperty(gdf, :shares) == true
        @test hasproperty(gdf, :purchase_price) == true
        @test gdf[gdf.symbol .== "IBM", :].purchase_price[1] == 140

        # mark to market
        df2 = copy(df)
        apply(ig_get_real_time_quote => mock_ig_get_quote_100) do
            @test_nowarn ig_mark_to_market!(df2)
            @test hasproperty(df2, :current_price)
            @test hasproperty(df2, :market_value)
            @test unique(df2.current_price) == [100]

            df3 = @test_nowarn ig_mark_to_market_portfolio(USER_ID)
            @test df3.current_price .* df3.shares == df3.market_value

            # compatible column names
            @test Set(propertynames(ig_cash_entry(pf))) == Set(propertynames(df3))

            # translation to string
            @test_nowarn ig_view_table(PrettyView(), df2)

            # SimpleView requires specific format
            @test_nowarn ig_reformat_view!(df3)
            @test_nowarn ig_view_table(SimpleView(), df3)
        end
    end

    test_ig_cases("Ranking") do
        ig_buy(USER_ID, "AAPL", 100, 60)
        ig_buy(USER_ID, "IBM", 100, 60)
        ig_buy(USER_ID2, "AAPL", 100, 120)  # bought at higher price i.e. less cash remaining
        ig_buy(USER_ID2, "IBM", 100, 120)
        apply(
            ig_get_real_time_quote => mock_ig_get_quote_100,
            retrieve_users => mock_retrieve_users,
        ) do
            valuations = @test_nowarn ig_value_all_portfolios()
            # ranking order: highest valuation is at the top
            @test valuations[1].id == USER_ID
            @test valuations[2].id == USER_ID2

            client = mocked_client()
            rt = @test_nowarn ig_ranking_table(client)
            @test rt[1, :player] == "$USER_ID"
            @test rt[2, :player] == "$USER_ID2"
        end
    end

    test_ig_cases("Executors") do
        c = Client("test")
        m = Message(; id = 0x00, channel_id = 0x00)
        u = User(; id = USER_ID3, username = USER_NAME)
        apply(
            discord_channel => mock_channel,
            discord_reply => mock_reply,
            discord_upload_file => mock_upload_file,
            ig_get_real_time_quote => mock_ig_get_quote_100,
            retrieve_users => mock_retrieve_users,
        ) do
            @test_nowarn ig_execute(c, m, u, Val(Symbol("start-game")), [])
            @test_nowarn ig_execute(c, m, u, Val(Symbol("abandon-game")), [])
            @test_nowarn ig_execute(c, m, u, Val(Symbol("abandon-game-really")), [])

            @test_nowarn ig_execute(c, m, u, Val(Symbol("start-game")), [])
            @test_nowarn ig_execute(c, m, u, Val(:view), [])
            @test_nowarn ig_execute(c, m, u, Val(:view), ["simple"])
            @test_nowarn ig_execute(c, m, u, Val(:buy), ["100", "aapl"])
            @test_nowarn ig_execute(c, m, u, Val(:sell), ["100", "aapl"])
            @test_nowarn ig_execute(c, m, u, Val(Symbol("abandon-game-really")), [])

            @test_nowarn ig_execute(c, m, u, Val(:quote), ["aapl"])
            @test_nowarn ig_execute(c, m, u, Val(:chart), ["aapl"])
            @test_nowarn ig_execute(c, m, u, Val(:chart), ["aapl", "100d"])

            @test_nowarn ig_execute(c, m, u, Val(:rank), [])
            @test_nowarn ig_execute(c, m, u, Val(:rank), ["10"])
        end
    end

    @testset "Misc" begin
        apply(current_date => mock_currrent_date) do
            r = @test_nowarn recent_date_range(Day(10))
            @test r isa Tuple{Date,Date}
            @test r[1] == Date(2021, 1, 1)
            @test r[2] == Date(2021, 1, 11)
        end
    end

    @testset "Charting" begin
        dates = collect(Date(2021, 1, 1):Day(1):Date(2021,12,31))
        values = collect(1:365)
        @test_nowarn ig_chart("AAPL", dates, values)
    end

    @testset "Integration tests" begin
        from_date, to_date = Date(2021, 1, 1), Date(2021, 1, 31)
        @test_nowarn ig_historical_prices("AAPL", from_date, to_date)
        @test_throws IgUserError ig_historical_prices("BADSYMBOL", from_date, to_date)
    end

    clean_ig_game_files()
end
