const QUOTE_CACHE = Cache{String,Float64}(Minute(1))

function commander(c::Client, m::Message, ::Val{:ig})
    @debug "ig_commander called"

    command = extract_command("ig", m.content)
    args = split(command)
    @debug "parse result" command args

    if length(args) == 0 ||
       args[1] ∉ [
        "start-game",
        "abandon-game",
        "quote",
        "chart",
        "buy",
        "sell",
        "perf",
        "rank",
        "view",
        "gl",
        "hist",
        "abandon-game-really",
    ]
        help_commander(c, m, :ig)
        return nothing
    end

    user = @discord retrieve(c, User, m.author.id)
    try
        ig_execute(c, m, user, Val(Symbol(args[1])), args[2:end])
    catch ex
        if ex isa IgUserError
            discord_reply(c, m, ig_hey(user.username, ex.message))
        elseif ex isa TaskFailedException && ex.task.result isa IgUserError
            discord_reply(c, m, ig_hey(user.username, ex.task.result.message))
        else
            discord_reply(
                c,
                m,
                ig_hey(
                    user.username,
                    "sorry, looks like you've hit a bug. Please report the problem.",
                ),
            )
            @error "Internal error" ex
            Base.showerror(stdout, ex, catch_backtrace())
        end
    end
end

function help_commander(c::Client, m::Message, ::Val{:ig})
    return discord_reply(
        c,
        m,
        """
        Play the investment game (ig). US market only for now.
        ```
        ig start-game
        ig abandon-game
        ```
        Research stocks:
        ```
        ig quote <symbol>            - get current price quote
        ig chart <symbol> [period]   - historical price chart
            Period is optional. Examples are: 200d, 36m, or 10y
            for 200 days, 36 months, or 10 years respectively.
        ```
        Manage portfolio:
        ```
        ig buy <n> <symbol>    - buy <n> shares of a stock
        ig sell <n> <symbol>   - sell <n> shares of a stock
        ig view                - view holdings and current market values
        ig perf                - compare with yesterday's EOD prices
        ig gl                  - gain/loss view of your current portfolio
        ig hist [<symbol>]     - purchase history
        ```
        How are you doing?
        ```
        ig rank [n]            - display top <n> portfolios, defaults to 5.
        ```
        """,
    )
end

"""
    ig_execute

This function executes any of the following commands.

# start-game
Start a new game by giving the player \$1MM USD.

# abandon-game
Abandon current game by wiping out the player's record.

# quote <symbol>
Fetch current market price of a stock.

# chart <symbol> <lookback>
The `lookback` argument is optional. If it is not specified, then it is defaulted
to 1 year. Otherwise, it takes the format of a number followed by `y`, `m`, or `d`
for number of years, months, or days respectively.

# buy <n> <symbol>
Buy `n` shares of a stock at the current market price. Player must have enough
cash to settle the trade.

# sell <n> <symbol>
Sell `n` shares of a stock at the current market price. Player must have
that many shares in the portfolio.

# view
Display detailed information about the portfolio, its holdings, and total market value.

# rank
Display top portfolios with highest market value.
"""
function ig_execute end

function ig_execute(c::Client, m::Message, user::User, ::Val{Symbol("start-game")}, args)
    ig_affirm_non_player(user.id)
    pf = ig_start_new_game(user.id)
    discord_reply(
        c,
        m,
        ig_hey(
            user.username,
            "you have \$" *
            format_amount(pf.cash) *
            " in your shiny new portfolio now! Good luck!",
        ),
    )
    return nothing
end

function ig_execute(c::Client, m::Message, user::User, ::Val{Symbol("abandon-game")}, args)
    ig_affirm_player(user.id)
    discord_reply(
        c,
        m,
        ig_hey(
            user.username,
            "do you REALLY want to abandon the game and wipe out all of your data? " *
            "If so, type `ig abandon-game-really`.",
        ),
    )
    return nothing
end

function ig_execute(
    c::Client, m::Message, user::User, ::Val{Symbol("abandon-game-really")}, args
)
    ig_affirm_player(user.id)
    ig_remove_game(user.id)
    discord_reply(
        c, m, ig_hey(user.username, "your investment game is now over. Play again soon!")
    )
    return nothing
end

function ig_execute(c::Client, m::Message, user::User, ::Val{:buy}, args)
    ig_affirm_player(user.id)
    length(args) == 2 || throw(
        IgUserError(
            "Invalid command. Try `ig buy 100 aapl` to buy 100 shares of Apple Inc."
        ),
    )

    symbol = strip(uppercase(args[2]))
    shares = tryparse(Int, args[1])
    shares !== nothing ||
        throw(IgUserError("please enter number of shares as a number: `$shares`"))

    purchase_price = ig_buy(user.id, symbol, shares)
    discord_reply(
        c,
        m,
        ig_hey(
            user.username,
            "you have bought $shares shares of $symbol at \$" *
            format_amount(purchase_price),
        ),
    )
    return nothing
end

function ig_execute(c::Client, m::Message, user::User, ::Val{:sell}, args)
    ig_affirm_player(user.id)
    length(args) == 2 || throw(
        IgUserError(
            "Invalid command. Try `ig sell 100 aapl` to sell 100 shares of Apple Inc."
        ),
    )

    symbol = strip(uppercase(args[2]))
    shares = tryparse(Int, args[1])
    shares !== nothing ||
        throw(IgUserError("please enter number of shares as a number: `$shares`"))

    current_price = ig_sell(user.id, symbol, shares)
    discord_reply(
        c,
        m,
        ig_hey(
            user.username,
            "you have sold $shares shares of $symbol at \$" * format_amount(current_price),
        ),
    )
    return nothing
end

function ig_execute(c::Client, m::Message, user::User, ::Val{:perf}, args)
    ig_affirm_player(user.id)
    df = ig_perf(user.id)
    table = pretty_table(String, df; header=names(df))
    discord_reply(c, m, ig_hey(
        user.username,
        """your stocks' performance today:
        ```
        $table
        ```
        """,
    ))
    return nothing
end

function ig_execute(c::Client, m::Message, user::User, ::Val{:gl}, args)
    ig_affirm_player(user.id)
    df = ig_gain_loss(user.id)
    page_size = 25  # approximate table size before exceeding Discord 2,000 char limit
    for (i, subdf) in enumerate(partition_table(df, page_size))
        if i == 1
            discord_reply(
                c, m, ig_hey(user.username, "here are the gains/losses for your stocks:")
            )
        end
        table = pretty_table(String, subdf; header=names(subdf))
        discord_reply(
            c,
            m,
            """
            ```
            $table
            ```
            """,
        )
    end
    return nothing
end

function ig_execute(c::Client, m::Message, user::User, ::Val{:hist}, args)
    ig_affirm_player(user.id)
    if length(args) >= 1
        symbol = uppercase(args[1])
        clause = " of $symbol"
    else
        symbol = nothing
        clause = ""
    end

    # when symbol is nothing, retrieve the purchase history for entire portfolio
    df = ig_hist(user.id, symbol)
    if nrow(df) > 0
        table = pretty_table(String, df; header=names(df))
        discord_reply(c, m, ig_hey(
            user.username,
            """here is the purchase history$clause:
            ```
            $table
            ```
            """,
        ))
    else
        msg = "no purchase history was found"
        if symbol !== nothing
            msg *= " for $symbol"
        end
        discord_reply(c, m, ig_hey(user.username, msg))
    end
    return nothing
end

"Return a data frame with daily performance of user's current holdings."
function ig_perf(user_id::UInt64)
    pf = ig_load_portfolio(user_id)
    symbols = unique(h.symbol for h in pf.holdings)
    prices_yesterday = fetch.(@async(ig_yesterday_price(s)) for s in symbols)
    prices_today = fetch.(@async(ig_get_quote(s)) for s in symbols)
    prices_change = prices_today .- prices_yesterday
    prices_change_pct = prices_change ./ prices_yesterday * 100
    df = DataFrame(;
        symbol=symbols,
        px_eod=prices_yesterday,
        px_now=prices_today,
        chg=round.(prices_change; digits=2),
        pct_chg=round.(prices_change_pct; digits=1),
    )
    rename!(df, "pct_chg" => "% chg")
    sort!(df, :symbol)
    return df
end

"Return a data frame with gains/losses for user's current holdings."
function ig_gain_loss(user_id::UInt64)
    pf = ig_load_portfolio(user_id)
    df = ig_grouped_holdings(ig_holdings_data_frame(pf))
    rename!(df, "purchase_price" => "px_buy")

    df.px_now = fetch.(@async(ig_get_quote(s)) for s in df.symbol)
    df.chg = round.(df.px_now .- df.px_buy; digits=2)
    df.pct_chg = round.(df.chg ./ df.px_buy * 100; digits=1)
    rename!(df, "pct_chg" => "% chg")

    df.shares = round.(Int, df.shares)

    return df
end

"Return a data frame with the purchase history of current holdings."
function ig_hist(user_id::UInt64, symbol::Optional{AbstractString})
    pf = ig_load_portfolio(user_id)
    df = ig_holdings_data_frame(pf)
    if symbol !== nothing
        filter!(:symbol => ==(symbol), df)
    end

    df.shares = round.(Int, df.shares)
    rename!(df, "purchase_price" => "px_buy")
    rename!(df, "purchase_date" => "date")

    sort!(df, [:symbol, :date, :px_buy])

    return df[!, [:symbol, :date, :px_buy, :shares]]
end

function ig_execute(c::Client, m::Message, user::User, ::Val{:view}, args)
    ig_affirm_player(user.id)

    df = ig_mark_to_market_portfolio(user.id)
    ig_reformat_view!(df)

    view = length(args) == 1 && args[1] == "simple" ? SimpleView() : PrettyView()
    table = ig_view_table(view, df)
    total_str = format_amount(round(Int, sum(df.amount)))

    discord_reply(c, m, ig_hey(
        user.username,
        """
        here is your portfolio:
        ```
        $table
        ```
        Total portfolio Value: $total_str
        """,
    ))

    ig_check_bad_stocks(c, m, user, df)

    return nothing
end

# If there's any unknown stocks, advise user to get rid of it
function ig_check_bad_stocks(c::Client, m::Message, user::User, df::AbstractDataFrame)
    bad_stocks = filter(r -> r.price == 0.0, df)
    if nrow(bad_stocks) > 0
        bad_stock_symbols = join(bad_stocks.symbol, ",")
        discord_reply(c, m, ig_hey(user.username,
            """
            You have some unknown stocks in your portfolio: $bad_stock_symbols
            Please use `sell` command to get rid of the bad positions.
            """))
    end
    return nothing
end

# Shorten colummn headings for better display in Discord
function ig_reformat_view!(df::AbstractDataFrame)
    select!(df, Not(:purchase_price))
    rename!(df, "current_price" => "price", "market_value" => "amount")
    return df
end

function ig_execute(c::Client, m::Message, user::User, ::Val{:quote}, args)
    length(args) == 1 || throw(
        IgUserError(
            "Invalid command. Try `ig quote aapl` to fetch the current price of Apple Inc.",
        ),
    )

    symbol = strip(uppercase(args[1]))
    price = ig_real_time_price(symbol)
    discord_reply(
        c,
        m,
        ig_hey(user.username, "the current price of $symbol is " * format_amount(price)),
    )
    return nothing
end

function ig_execute(c::Client, m::Message, user::User, ::Val{:chart}, args)
    1 <= length(args) <= 2 || throw(
        IgUserError("Invalid command. Try `ig chart aapl` to see a chart for Apple Inc."),
    )

    ch = discord_channel(c, m.channel_id)
    symbol = strip(uppercase(args[1]))
    lookback = length(args) == 1 ? Year(1) : date_period(lowercase(args[2]))
    from_date, to_date = recent_date_range(lookback)
    df = ig_historical_prices(symbol, from_date, to_date)
    filename = ig_chart(symbol, df.Date, df."Adj Close")
    discord_upload_file(
        c,
        ch,
        filename;
        content=ig_hey(
            user.username,
            "here is the chart for $symbol for the past $lookback. " *
            "To plot a chart with different time horizon, " *
            "try something like `ig chart $symbol 90d` or `ig chart $symbol 10y`.",
        ),
    )
    return nothing
end

function ig_execute(c::Client, m::Message, user::User, ::Val{:rank}, args)
    length(args) <= 1 ||
        throw(IgUserError("Invalid command. Try `ig rank` or `ig rank 10`"))

    n = length(args) == 0 ? 5 : tryparse(Int, args[1])
    n !== nothing || throw(
        IgUserError(
            "invalid rank argument `$(args[1])`. " * "Try `ig rank` or `ig rank 10`"
        ),
    )

    rt = ig_ranking_table(c)
    rt = rt[1:min(n, nrow(rt)), :]  # get top N results
    rt_str = ig_view_table(PrettyView(), rt)

    discord_reply(c, m, ig_hey(
        user.username,
        """here's the current ranking:
        ```
        $rt_str
        ```
        """,
    ))
    return nothing
end

function ig_ranking_table(c::Client)
    valuations = ig_value_all_portfolios()
    if length(valuations) > 0
        users_dict = retrieve_users(c, [v.id for v in valuations])
        @debug "ig_ranking_table" valuations
        @debug "ig_ranking_table" users_dict
        df = DataFrame(;
            rank=1:length(valuations),
            player=[users_dict[v.id].username for v in valuations],
            portfolio_value=[v.total for v in valuations],
        )
        return df
    else
        return DataFrame(; player=String[], portfolio_value=Float64[])
    end
end

@mockable function retrieve_users(c::Client, ids::Vector{UInt64})
    futures = retrieve.(Ref(c), User, ids)
    responses = fetch.(futures)
    unknown = User(; id=UInt64(0), username="Unknown")
    return Dict(
        k => res.val === nothing ? unknown : res.val for (k, res) in zip(ids, responses)
    )
end

function ig_value_all_portfolios()
    pfs = ig_load_all_portfolios()
    valuations = []
    for (id, pf) in pfs
        @debug "Evaluating portfolio" id pf
        df = ig_mark_to_market!(ig_holdings_data_frame(pf))
        mv = nrow(df) > 0 ? sum(df.market_value) : 0.0
        cash = pf.cash
        total = mv + cash
        push!(valuations, (; id, mv, cash, total))
    end
    sort!(valuations; lt=(x, y) -> x.total < y.total, rev=true)
    # @info "ig_value_all_portfolios result" valuations
    return valuations
end

"Format money amount"
format_amount(x::Real) = format(x; commas=true, precision=2)
format_amount(x::Integer) = format(x; commas=true)

"Pretty table formatters"
decimal_formatter(v, i, j) = v isa Real ? format_amount(v) : v
integer_formatter(v, i, j) = v isa Real ? format_amount(round(Int, v)) : v

"Hey someone"
function ig_hey(username::AbstractString, message::AbstractString)
    s = "Hey, " * username * ", " * message
    threshold = 1800
    len = length(s)
    len > threshold && @warn("Message size $len is close to Discord's 2,000 limit.")
    return s
end

"File location of the game file for a user"
ig_file_path(user_id::UInt64) = joinpath(ig_data_directory(), "$user_id.json")

"Directory of the investment game data files"
ig_data_directory() = joinpath("data", "ig")

"Returns true if user already has a game in progress."
ig_is_player(user_id::UInt64) = isfile(ig_file_path(user_id))

"Start a new game file"
function ig_start_new_game(user_id::UInt64)
    pf = IgPortfolio(1_000_000.00, IgHolding[])
    ig_save_portfolio(user_id, pf)
    return pf
end

"Destroy the existing game file for a user."
ig_remove_game(user_id::UInt64) = rm(ig_file_path(user_id))

"Affirms the user has a game or throw an exception."
function ig_affirm_player(user_id::UInt64)
    ig_is_player(user_id) || throw(
        IgUserError("you don't have a game yet. Type `ig start-game` to start a new game."),
    )
    return nothing
end

"Affirms the user does not have game or throw an exception."
function ig_affirm_non_player(user_id::UInt64)
    !ig_is_player(user_id) || throw(
        IgUserError(
            "you already have a game running. Type `ig view` to see your current portfolio.",
        ),
    )
    return nothing
end

"Save a user portfolio in the data directory."
function ig_save_portfolio(user_id::UInt64, pf::IgPortfolio)
    @debug "Saving portfolio" user_id
    path = ig_file_path(user_id)
    write(ensurepath!(path), JSON3.write(pf))
    return nothing
end

"Load the portfolio for a single user"
function ig_load_portfolio(user_id::UInt64)
    @debug "Loading portfolio" user_id
    path = ig_file_path(user_id)
    return ig_load_portfolio(path)
end

"Load a single portfolio from game file"
function ig_load_portfolio(path::AbstractString)
    bytes = read(path)
    return JSON3.read(bytes, IgPortfolio)
end

"Extract user id from the portfolio data file"
function ig_user_id_from_path(path::AbstractString)
    filename = basename(path)
    filename_without_extension = replace(filename, r"\.json$" => "")
    return parse(UInt64, filename_without_extension)
end

"Load all game files"
function ig_load_all_portfolios()
    dir = ig_data_directory()
    files = readdir(dir)
    user_ids = ig_user_id_from_path.(files)
    return Dict(
        user_id => ig_load_portfolio(joinpath(dir, file)) for
        (user_id, file) in zip(user_ids, files)
    )
end

"Fetch quote of a stock, but possibly with a time delay."
function ig_get_quote(symbol::AbstractString)
    return get!(QUOTE_CACHE, symbol) do
        return ig_real_time_price(symbol)
    end
end

"Buy stock for a specific user at a specific price."
function ig_buy(
    user_id::UInt64,
    symbol::AbstractString,
    shares::Real,
    current_price::Real=ig_real_time_price(symbol),
)
    @debug "Buying stock" user_id symbol shares
    current_price > 0.0 ||
        throw(IgUserError("No price is found for $symbol. Is it a valid stock symbol?"))
    pf = ig_load_portfolio(user_id)
    cost = shares * current_price
    if pf.cash >= cost
        pf.cash -= cost
        push!(pf.holdings, IgHolding(symbol, shares, current_date(), current_price))
        ig_save_portfolio(user_id, pf)
        return current_price
    end
    return throw(
        IgUserError(
            "you don't have enough cash. " *
            "Buying $shares shares of $symbol will cost you $(format_amount(cost)) " *
            "but you only have $(format_amount(pf.cash))",
        ),
    )
end

"Sell stock for a specific user. Returns executed price."
function ig_sell(
    user_id::UInt64,
    symbol::AbstractString,
    shares::Real,
    current_price::Real=ig_real_time_price(symbol),
)
    @debug "Selling stock" user_id symbol shares
    pf = ig_load_portfolio(user_id)
    pf_new = ig_sell_fifo(pf, symbol, shares, current_price)
    ig_save_portfolio(user_id, pf_new)
    return current_price
end

"Sell stock based upon FIFO accounting scheme. Returns the resulting `IgPortfolio` object."
function ig_sell_fifo(
    pf::IgPortfolio, symbol::AbstractString, shares::Real, current_price::Real
)
    existing_shares = ig_count_shares(pf, symbol)
    if existing_shares == 0
        throw(IgUserError("you do not have $symbol in your portfolio"))
    elseif shares > existing_shares
        existing_shares_str = format_amount(round(Int, existing_shares))
        throw(
            IgUserError(
                "you cannot sell more than what you own ($existing_shares_str shares)"
            ),
        )
    end

    proceeds = shares * current_price

    # Construct a new IgPortfolio object that contains the resulting portfolio after
    # selling the stock. The following logic does it incrementally but just for documentation
    # purpose an alternative algorithm would be to make a copy and then relief the sold lots.
    holdings = IgHolding[]
    pf_new = IgPortfolio(pf.cash + proceeds, holdings)
    remaining = shares   # keep track of how much to sell
    for h in pf.holdings
        if h.symbol != symbol || remaining == 0
            push!(holdings, h)
        else
            if h.shares > remaining  # relief lot partially
                revised_lot = IgHolding(
                    symbol, h.shares - remaining, h.date, h.purchase_price
                )
                push!(holdings, revised_lot)
                remaining = 0
            else # relief this lot completely and continue
                remaining -= h.shares
            end
        end
    end
    return pf_new
end

"""
Returns a data frame for the portfolio holdings.
Note that:
1. It does not include cash portion of the portfolio
2. Multiple lots of the same stock will be in different rows

See also: `ig_grouped_holdings`(@ref)
"""
function ig_holdings_data_frame(pf::IgPortfolio)
    return DataFrame(;
        symbol=[h.symbol for h in pf.holdings],
        shares=[h.shares for h in pf.holdings],
        purchase_price=[h.purchase_price for h in pf.holdings],
        purchase_date=[h.date for h in pf.holdings],
    )
end

"Returns grouped holdings by symbol with average purchase price"
function ig_grouped_holdings(df::AbstractDataFrame)
    df = combine(groupby(df, :symbol)) do sdf
        shares = sum(sdf.shares)
        weights = sdf.shares / shares
        purchase_price = sum(weights .* sdf.purchase_price)
        return (; shares, purchase_price)
    end
    return sort!(df, :symbol)
end

"Return a data frame with the user's portfolio marked to market."
function ig_mark_to_market_portfolio(user_id::UInt64)
    pf = ig_load_portfolio(user_id)
    df = ig_grouped_holdings(ig_holdings_data_frame(pf))
    cash_entry = ig_cash_entry(pf)
    if nrow(df) > 0
        ig_mark_to_market!(df)
        push!(df, cash_entry)
    else
        df = DataFrame([cash_entry])
    end
    return df
end

"Return the portoflio cash as named tuple that can be appended to the portfolio data frame."
function ig_cash_entry(pf::IgPortfolio)
    return (
        symbol="CASH:USD",
        shares=pf.cash,
        purchase_price=1.0,
        current_price=1.0,
        market_value=pf.cash,
    )
end

"Add columns with current price and market value"
function ig_mark_to_market!(df::AbstractDataFrame)
    df.current_price = fetch.(@async(ig_get_quote(s)) for s in df.symbol)
    df.market_value = df.shares .* df.current_price
    return df
end

"Format data frame using pretty table"
function ig_view_table(::PrettyView, df::AbstractDataFrame)
    return pretty_table(String, df; formatters=integer_formatter, header=names(df))
end

"Return portfolio view as string in a simple format"
function ig_view_table(::SimpleView, df::AbstractDataFrame)
    io = IOBuffer()
    # @show "ig_view_table" df
    for (i, r) in enumerate(eachrow(df))
        if !startswith(r.symbol, "CASH:")
            println(
                io,
                i,
                ". ",
                r.symbol,
                ": ",
                round(Int, r.shares),
                " x \$",
                format_amount(r.price),
                " = \$",
                format_amount(round(Int, r.amount)),
            )
        else
            println(io, i, ". ", r.symbol, " = ", format_amount(round(Int, r.amount)))
        end
    end

    return String(take!(io))
end

"Returns a tuple of two dates by looking back from today's date"
function recent_date_range(lookback::DatePeriod)
    T = current_date()
    to_date = T
    from_date = T - lookback
    return from_date, to_date
end

@mockable current_date() = today()

"""
Return a data frame with historical prices data. Columns include:
- `Date`
- `Open`
- `High`
- `Low`
- `Close`
- `Adj Close`
- `Volume`
"""
function ig_historical_prices(symbol::AbstractString, from_date::Date, to_date::Date)
    from_sec = seconds_since_1970(from_date)
    to_sec = seconds_since_1970(to_date + Day(1))  # apparently, Yahoo is exclusive on this end
    symbol = HTTP.escapeuri(symbol)
    url =
        "https://query1.finance.yahoo.com/v7/finance/download/$symbol?" *
        "period1=$from_sec&period2=$to_sec&interval=1d&events=history&includeAdjustedClose=true"
    try
        elapsed = @elapsed df = DataFrame(
            CSV.File(Downloads.download(url); missingstring="null")
        )
        dropmissing!(df)
        @info "$(now())\tig_historical_prices\t$symbol\t$from_date\t$to_date\t$elapsed"
        return df
    catch ex
        if ex isa Downloads.RequestError && ex.response.status == 404
            throw(
                IgUserError(
                    "there is no historical prices for $symbol. Is it a valid stock symbol?"
                ),
            )
        else
            rethrow()
        end
    end
end

"Return yesterday's EOD pricing data"
@mockable ig_yesterday_price(symbol::AbstractString) = ig_latest_price(symbol, Day(1))

"Return real-time pricing data"
@mockable ig_real_time_price(symbol::AbstractString) = ig_latest_price(symbol, Day(0))

# Using Yahoo's historical price query to find the latest price
# Fortunately, Yahoo also provides real-time prices, so setting offset to Day(0)
# would return the current price.
function ig_latest_price(symbol::AbstractString, offset::DatePeriod)
    try
        to_date = today() - offset
        from_date = to_date - Day(4)   # account for weekend and holidays
        df = ig_historical_prices(symbol, from_date, to_date)
        if nrow(df) >= 1
            return df[end, "Adj Close"]
        else
            return 0.0
        end
    catch ex
        @error "Unable to find price for $symbol, defaulting to zero. Exception=$ex"
        return 0.0
    end
end

"Plot a simple price chart"
function ig_chart(symbol::AbstractString, dates::Vector{Date}, values::Vector{<:Real})
    from_date, to_date = extrema(dates)
    last_price_str = format_amount(last(values))
    c = crplot(
        dates,
        values;
        xticks=5,
        yticks=10,
        title="$symbol Historical Prices ($from_date to $to_date)\nLast price: $last_price_str",
    )
    filename = tempname() * ".png"
    CairoPlot.write_to_png(c, filename)
    return filename
end

"Find lots for a specific stock in the portfolio. Sort by purchase date."
function ig_find_lots(pf::IgPortfolio, symbol::AbstractString)
    lots = IgHolding[x for x in pf.holdings if x.symbol == symbol]
    return sort(lots; lt=(x, y) -> x.date < y.date)
end

"Return total number of shares for a specific stock in the portfolio."
function ig_count_shares(pf::IgPortfolio, symbol::AbstractString)
    lots = ig_find_lots(pf, symbol)
    return length(lots) > 0 ? round(sum(lot.shares for lot in lots); digits=0) : 0
    # note that we store shares as Float64 but uses it as Int (for now)
end

seconds_since_1970(d::Date) = (d - Day(719163)).instant.periods.value * 24 * 60 * 60

function date_period(s::AbstractString)
    m = match(r"^(\d+)([ymd])$", s)
    m !== nothing || throw(IgUserError("invalid date period: $s. Try `5y` or `30m`."))
    num = parse(Int, m.captures[1])
    dct = Dict("y" => Year, "m" => Month, "d" => Day)
    return dct[m.captures[2]](num)
end
