Code.require_file("transaction_helper.exs", __DIR__)

defmodule XtbClient.ConnectionTest do
  use ExUnit.Case, async: true
  doctest XtbClient.Connection

  alias XtbClient.Connection

  alias XtbClient.Messages.{
    BalanceInfo,
    CalendarInfos,
    CalendarInfo,
    Candle,
    Candles,
    ChartLast,
    ChartRange,
    CommissionDefinition,
    DateRange,
    KeepAlive,
    MarginTrade,
    NewsInfos,
    NewsInfo,
    ProfitCalculation,
    ProfitInfo,
    Quote,
    Quotations,
    RateInfos,
    RateInfo,
    ServerTime,
    StepRules,
    StepRule,
    Step,
    SymbolInfo,
    SymbolInfos,
    SymbolVolume,
    TickPrices,
    TickPrice,
    TradeInfos,
    TradeInfo,
    Trades,
    TradeStatus,
    TradeTransaction,
    TradeTransactionStatus,
    TradingHours,
    TradingHour,
    UserInfo,
    Version
  }

  alias XtbClient.TransactionHelper

  setup_all do
    Dotenvy.source([
      ".env.#{Mix.env()}",
      ".env.#{Mix.env()}.override",
      System.get_env()
    ])

    url = Dotenvy.env!("XTB_API_URL", :string!)
    user = Dotenvy.env!("XTB_API_USERNAME", :string!)
    passwd = Dotenvy.env!("XTB_API_PASSWORD", :string!)

    params = %{
      url: url,
      user: user,
      password: passwd,
      type: :demo,
      app_name: "XtbClient"
    }

    {:ok, pid} = Connection.start_link(params)
    # :sys.trace(pid, true)

    {:ok, %{pid: pid}}
  end

  test "get all symbols", %{pid: pid} do
    result = Connection.get_all_symbols(pid)

    assert %SymbolInfos{} = result
    assert [elem | _] = result.data
    assert %SymbolInfo{} = elem
  end

  test "get calendar", %{pid: pid} do
    result = Connection.get_calendar(pid)

    assert %CalendarInfos{} = result
    assert [elem | _] = result.data
    assert %CalendarInfo{} = elem
  end

  test "get chart last", %{pid: pid} do
    args = %{
      period: :h1,
      start: DateTime.utc_now() |> DateTime.add(-30 * 24 * 60 * 60),
      symbol: "EURPLN"
    }

    query = ChartLast.Query.new(args)
    result = Connection.get_chart_last(pid, query)

    assert %RateInfos{} = result
    assert is_number(result.digits)
    assert [elem | _] = result.data
    assert %RateInfo{} = elem
  end

  test "get chart range", %{pid: pid} do
    args = %{
      start: DateTime.utc_now() |> DateTime.add(-2 * 30 * 24 * 60 * 60),
      end: DateTime.utc_now(),
      period: :h1,
      symbol: "EURPLN"
    }

    query = ChartRange.Query.new(args)
    result = Connection.get_chart_range(pid, query)

    assert %RateInfos{} = result
    assert is_number(result.digits)
    assert [elem | _] = result.data
    assert %RateInfo{} = elem
  end

  test "get commission definition", %{pid: pid} do
    args = %{symbol: "EURPLN", volume: 1}
    query = SymbolVolume.new(args)
    result = Connection.get_commission_def(pid, query)

    assert %CommissionDefinition{} = result
  end

  test "get current user data", %{pid: pid} do
    result = Connection.get_current_user_data(pid)

    assert %UserInfo{} = result
  end

  test "get margin level", %{pid: pid} do
    result = Connection.get_margin_level(pid)

    assert %BalanceInfo{} = result
  end

  test "get margin trade", %{pid: pid} do
    args = %{symbol: "EURPLN", volume: 1}
    query = SymbolVolume.new(args)
    result = Connection.get_margin_trade(pid, query)

    assert %MarginTrade{} = result
  end

  test "get news", %{pid: pid} do
    args = %{
      from: DateTime.utc_now() |> DateTime.add(-2 * 30 * 24 * 60 * 60),
      to: DateTime.utc_now()
    }

    query = DateRange.new(args)
    result = Connection.get_news(pid, query)

    assert %NewsInfos{} = result
    assert [elem | _] = result.data
    assert %NewsInfo{} = elem
  end

  test "get profit calculation", %{pid: pid} do
    args = %{
      open_price: 1.2233,
      close_price: 1.3,
      operation: :buy,
      symbol: "EURPLN",
      volume: 1.0
    }

    query = ProfitCalculation.Query.new(args)
    result = Connection.get_profit_calculation(pid, query)

    assert %ProfitCalculation{} = result
  end

  test "get server time", %{pid: pid} do
    result = Connection.get_server_time(pid)

    assert %ServerTime{} = result
  end

  test "get step rules", %{pid: pid} do
    result = Connection.get_step_rules(pid)

    assert %StepRules{} = result
    assert [elem | _] = result.data
    assert %StepRule{steps: [step | _]} = elem
    assert %Step{} = step
  end

  test "get symbol", %{pid: pid} do
    query = SymbolInfo.Query.new("BHW.PL_9")
    result = Connection.get_symbol(pid, query)

    assert %SymbolInfo{} = result
  end

  test "get tick prices", %{pid: pid} do
    args = %{
      level: 0,
      symbols: ["EURPLN"],
      timestamp: DateTime.utc_now() |> DateTime.add(-2 * 60)
    }

    query = TickPrices.Query.new(args)
    result = Connection.get_tick_prices(pid, query)

    assert %TickPrices{} = result
    assert [elem | _] = result.data
    assert %TickPrice{} = elem
  end

  test "get trades history", %{pid: pid} do
    args = %{
      from: DateTime.utc_now() |> DateTime.add(-3 * 31 * 24 * 60 * 60),
      to: DateTime.utc_now()
    }

    query = DateRange.new(args)
    result = Connection.get_trades_history(pid, query)

    assert %TradeInfos{} = result
    assert [elem | _] = result.data
    assert %TradeInfo{} = elem
  end

  test "get trading hours", %{pid: pid} do
    args = ["EURPLN", "AGO.PL_9"]
    query = TradingHours.Query.new(args)

    result = Connection.get_trading_hours(pid, query)

    assert %TradingHours{} = result
    assert [elem | _] = result.data
    assert %TradingHour{} = elem
    assert [qu | _] = elem.quotes
    assert [trading | _] = elem.trading
    assert %Quote{} = qu
    assert %Quote{} = trading
  end

  test "get version", %{pid: pid} do
    result = Connection.get_version(pid)

    assert %Version{} = result
  end

  test "trade transaction - open and close transaction", %{pid: pid} do
    buy_args = %{
      operation: :buy,
      custom_comment: "Buy transaction",
      price: 1200.0,
      symbol: "LITECOIN",
      type: :open,
      volume: 0.5
    }

    buy = TradeTransaction.Command.new(buy_args)
    result = Connection.trade_transaction(pid, buy)

    assert %TradeTransaction{} = result

    # needs some time for server to process order correctly
    Process.sleep(100)

    open_order_id = result.order
    status = TradeTransactionStatus.Query.new(open_order_id)
    result = Connection.trade_transaction_status(pid, status)

    assert %TradeTransactionStatus{} = result

    # needs some time for server to process order correctly
    Process.sleep(100)

    # 1. way - get all opened only trades
    trades_query = Trades.Query.new(true)
    result = Connection.get_trades(pid, trades_query)

    assert %TradeInfos{} = result

    position_to_close =
      result.data
      |> Enum.find(&(&1.order_closed == open_order_id))

    # 2. way - get trades by position IDs
    trades_records_query = TradeInfos.Query.new([position_to_close.position])
    result = Connection.get_trade_records(pid, trades_records_query)

    assert %TradeInfos{} = result

    close_args = %{
      operation: :buy,
      custom_comment: "Close transaction",
      price: position_to_close.open_price - 0.01,
      symbol: "LITECOIN",
      order: position_to_close.order_opened,
      type: :close,
      volume: 0.5
    }

    close = TradeTransaction.Command.new(close_args)
    result = Connection.trade_transaction(pid, close)

    assert %TradeTransaction{} = result

    # needs some time for server to process order correctly
    Process.sleep(100)

    close_order_id = result.order
    status = TradeTransactionStatus.Query.new(close_order_id)
    result = Connection.trade_transaction_status(pid, status)

    assert %TradeTransactionStatus{status: :accepted} = result
  end

  test "subscribe to get balance", %{pid: pid} do
    buy_args = %{
      operation: :buy,
      custom_comment: "Buy transaction",
      price: 1200.0,
      symbol: "LITECOIN",
      type: :open,
      volume: 0.5
    }

    buy = TradeTransaction.Command.new(buy_args)
    result = Connection.trade_transaction(pid, buy)

    assert %TradeTransaction{} = result
    open_order_id = result.order

    # needs some time for server to process order correctly
    Process.sleep(1000)

    # real test scneario
    Connection.subscribe_get_balance(pid, self())

    # wait for some ticks
    Process.sleep(5 * 1000)

    # 1. way - get all opened only trades
    trades_query = Trades.Query.new(true)
    result = Connection.get_trades(pid, trades_query)

    assert %TradeInfos{} = result

    position_to_close =
      result.data
      |> Enum.find(&(&1.order_closed == open_order_id))

    close_args = %{
      operation: :buy,
      custom_comment: "Close transaction",
      price: position_to_close.open_price - 0.01,
      symbol: "LITECOIN",
      order: position_to_close.order_opened,
      type: :close,
      volume: 0.5
    }

    close = TradeTransaction.Command.new(close_args)
    result = Connection.trade_transaction(pid, close)

    assert %TradeTransaction{} = result
  end

  @tag timeout: 2 * 60 * 1000
  test "subscribe to get candles", %{pid: pid} do
    args = "EURPLN"
    query = Candles.Query.new(args)
    Connection.subscribe_get_candles(pid, self(), query)

    assert_receive {:ok, %Candle{}}, 2 * 60 * 1000
  end

  test "subscribe to keep alive", %{pid: pid} do
    Connection.subscribe_keep_alive(pid, self())

    assert_receive {:ok, %KeepAlive{}}, 4 * 1000
  end

  @tag timeout: 2 * 60 * 1000, skip: true
  test "subscribe to get news", %{pid: pid} do
    Connection.subscribe_get_news(pid, self())

    assert_receive {:ok, %NewsInfo{}}, 2 * 60 * 1000
  end

  test "subscribe to get profits", %{pid: pid} do
    Connection.subscribe_get_profits(pid, self())

    buy_args = %{
      operation: :buy,
      custom_comment: "Buy transaction",
      price: 1200.0,
      symbol: "LITECOIN",
      type: :open,
      volume: 0.5
    }

    order_id = TransactionHelper.open_trade(pid, buy_args)

    assert_receive {:ok, %ProfitInfo{}}, 20 * 1000

    close_args = %{
      operation: :buy,
      custom_comment: "Close transaction",
      symbol: "LITECOIN",
      type: :close,
      volume: 0.5
    }

    # wait for some ticks
    Process.sleep(5 * 1000)

    TransactionHelper.close_trade(pid, order_id, close_args)

    assert_receive {:ok, %ProfitInfo{}}, 20 * 1000
  end

  test "subscribe to get tick prices", %{pid: pid} do
    args = %{symbol: "LITECOIN"}
    query = Quotations.Query.new(args)
    Connection.subscribe_get_tick_prices(pid, self(), query)

    assert_receive {:ok, %TickPrice{}}, 5 * 1000
  end

  test "subscribe to get trades", %{pid: pid} do
    Connection.subscribe_get_trades(pid, self())

    buy_args = %{
      operation: :buy,
      custom_comment: "Buy transaction",
      price: 1200.0,
      symbol: "LITECOIN",
      type: :open,
      volume: 0.5
    }

    order_id = TransactionHelper.open_trade(pid, buy_args)

    assert_receive {:ok, %TradeInfo{}}, 20 * 1000

    close_args = %{
      operation: :buy,
      custom_comment: "Close transaction",
      symbol: "LITECOIN",
      type: :close,
      volume: 0.5
    }

    # wait for some ticks
    Process.sleep(5 * 1000)

    TransactionHelper.close_trade(pid, order_id, close_args)

    assert_receive {:ok, %TradeInfo{}}, 20 * 1000
  end

  test "subscribe to trade status", %{pid: pid} do
    Connection.subscribe_get_trade_status(pid, self())

    buy_args = %{
      operation: :buy,
      custom_comment: "Buy transaction",
      price: 1200.0,
      symbol: "LITECOIN",
      type: :open,
      volume: 0.5
    }

    order_id = TransactionHelper.open_trade(pid, buy_args)

    assert_receive {:ok, %TradeStatus{}}, 20 * 1000
    assert_receive {:ok, %TradeStatus{}}, 20 * 1000

    close_args = %{
      operation: :buy,
      custom_comment: "Close transaction",
      symbol: "LITECOIN",
      type: :close,
      volume: 0.5
    }

    TransactionHelper.close_trade(pid, order_id, close_args)

    assert_receive {:ok, %TradeStatus{}}, 20 * 1000
    assert_receive {:ok, %TradeStatus{}}, 20 * 1000
  end
end
