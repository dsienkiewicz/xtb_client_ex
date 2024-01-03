defmodule XtbClient.MainSocketTest do
  @moduledoc false
  use ExUnit.Case
  doctest XtbClient.MainSocket

  alias XtbClient.MainSocket

  alias XtbClient.Messages.{
    BalanceInfo,
    CalendarInfo,
    CalendarInfos,
    Candle,
    ChartLast,
    ChartRange,
    CommissionDefinition,
    DateRange,
    MarginTrade,
    NewsInfo,
    NewsInfos,
    ProfitCalculation,
    Quote,
    RateInfos,
    ServerTime,
    Step,
    StepRule,
    StepRules,
    SymbolInfo,
    SymbolInfos,
    SymbolVolume,
    TickPrice,
    TickPrices,
    TradeInfo,
    TradeInfos,
    Trades,
    TradeStatus,
    TradeTransaction,
    TradeTransactionStatus,
    TradingHour,
    TradingHours,
    UserInfo,
    Version
  }

  alias XtbClient.StreamingSocket
  alias XtbClient.StreamingSocketMock
  alias XtbClient.StreamingTestStoreMock

  import XtbClient.MainSocket.E2EFixtures

  setup do
    Dotenvy.source([
      ".env.#{Mix.env()}",
      ".env.#{Mix.env()}.override",
      System.get_env()
    ])

    url = Dotenvy.env!("XTB_API_URL", :string!)
    user = Dotenvy.env!("XTB_API_USERNAME", :string!)
    passwd = Dotenvy.env!("XTB_API_PASSWORD", :string!)

    params = [
      url: url,
      type: :demo,
      user: user,
      password: passwd,
      app_name: "XtbClient"
    ]

    {:ok, %{params: params}}
  end

  describe "session management" do
    @tag timeout: 40 * 1000
    test "sends ping after login", %{params: params} do
      {:ok, pid} = MainSocket.start_link(params)

      Process.sleep(30 * 1000 + 1)

      assert Process.alive?(pid) == true
    end

    test "can be managed by dynamic supervisor", %{params: params} do
      {:ok, _} =
        DynamicSupervisor.start_link(
          strategy: :one_for_one,
          name: XtbClient.MainDynamicSupervisor
        )

      {:ok, pid} =
        DynamicSupervisor.start_child(XtbClient.MainDynamicSupervisor, {MainSocket, params})

      assert Process.alive?(pid) == true
      assert Process.exit(pid, :kill) == true

      Process.sleep(100)

      assert [{:undefined, _, :worker, [MainSocket]}] =
               DynamicSupervisor.which_children(XtbClient.MainDynamicSupervisor)
    end

    test "handles additional params to start_link/2", %{params: params} do
      params = Keyword.merge(params, name: MainSocketTest)
      {:ok, pid} = MainSocket.start_link(params)

      assert Process.whereis(MainSocketTest) == pid
    end
  end

  describe "public API" do
    setup :setup_main_socket

    test "stream_session_id is present", %{pid: pid} do
      # needed to wait for socket to connect
      # during that time stream_session_id should be available
      Process.sleep(100)

      {:ok, stream_session_id} = MainSocket.stream_session_id(pid)
      assert is_binary(stream_session_id)
    end

    @tag timeout: 40 * 1000
    test "sends ping after login", %{pid: pid} do
      Process.sleep(30 * 1000 + 1)

      assert Process.alive?(pid) == true
    end

    test "get all symbols", %{pid: pid} do
      assert {:ok, %SymbolInfos{data: data}} = MainSocket.get_all_symbols(pid)
      assert [elem | _] = data
      assert %SymbolInfo{} = elem
    end

    test "get calendar", %{pid: pid} do
      assert {:ok, %CalendarInfos{data: data}} = MainSocket.get_calendar(pid)
      assert [elem | _] = data
      assert %CalendarInfo{} = elem
    end

    test "get chart last", %{pid: pid} do
      now = DateTime.utc_now()

      args = %{
        period: :h1,
        start: DateTime.add(now, -30 * 24 * 60 * 60),
        symbol: "EURPLN"
      }

      query = ChartLast.Query.new(args)

      assert {:ok, %RateInfos{data: data, digits: digits}} = MainSocket.get_chart_last(pid, query)
      assert is_number(digits)
      assert [elem | _] = data

      assert %Candle{
               symbol: symbol,
               open: open,
               high: high,
               low: low,
               close: close,
               vol: vol,
               ctm: ctm,
               ctm_string: ctm_string,
               quote_id: quote_id
             } = elem

      assert "EURPLN" == symbol
      assert is_number(open)
      assert is_number(high)
      assert is_number(low)
      assert is_number(close)
      assert is_number(vol)
      assert DateTime.compare(ctm, now) == :lt
      assert is_binary(ctm_string)
      refute quote_id
    end

    test "get chart range", %{pid: pid} do
      now = DateTime.utc_now()

      args = %{
        range:
          DateRange.new(%{
            from: DateTime.add(now, -2 * 30 * 24 * 60 * 60),
            to: now
          }),
        period: :h1,
        symbol: "EURPLN"
      }

      query = ChartRange.Query.new(args)

      assert {:ok, %RateInfos{data: data, digits: digits}} =
               MainSocket.get_chart_range(pid, query)

      assert is_number(digits)
      assert [elem | _] = data

      assert %Candle{
               symbol: symbol,
               open: open,
               high: high,
               low: low,
               close: close,
               vol: vol,
               ctm: ctm,
               ctm_string: ctm_string,
               quote_id: quote_id
             } = elem

      assert "EURPLN" == symbol
      assert is_number(open)
      assert is_number(high)
      assert is_number(low)
      assert is_number(close)
      assert is_number(vol)
      assert DateTime.compare(ctm, now) == :lt
      assert is_binary(ctm_string)
      refute quote_id
    end

    test "get commission definition", %{pid: pid} do
      args = %{symbol: "EURPLN", volume: 1}
      query = SymbolVolume.new(args)

      assert {:ok, %CommissionDefinition{}} = MainSocket.get_commission_def(pid, query)
    end

    test "get current user data", %{pid: pid} do
      assert {:ok, %UserInfo{}} = MainSocket.get_current_user_data(pid)
    end

    test "get margin level", %{pid: pid} do
      assert {:ok, %BalanceInfo{}} = MainSocket.get_margin_level(pid)
    end

    test "get margin trade", %{pid: pid} do
      args = %{symbol: "EURPLN", volume: 1}
      query = SymbolVolume.new(args)

      assert {:ok, %MarginTrade{}} = MainSocket.get_margin_trade(pid, query)
    end

    test "get news", %{pid: pid} do
      args = %{
        from: DateTime.add(DateTime.utc_now(), -2 * 30 * 24 * 60 * 60),
        to: DateTime.utc_now()
      }

      query = DateRange.new(args)

      assert {:ok, %NewsInfos{data: data}} = MainSocket.get_news(pid, query)
      assert [elem | _] = data
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

      assert {:ok, %ProfitCalculation{}} = MainSocket.get_profit_calculation(pid, query)
    end

    test "get server time", %{pid: pid} do
      assert {:ok, %ServerTime{}} = MainSocket.get_server_time(pid)
    end

    test "get step rules", %{pid: pid} do
      assert {:ok, %StepRules{data: data}} = MainSocket.get_step_rules(pid)
      assert [elem | _] = data
      assert %StepRule{steps: [step | _]} = elem
      assert %Step{} = step
    end

    test "get symbol", %{pid: pid} do
      query = SymbolInfo.Query.new("BHW.PL_9")

      assert {:ok, %SymbolInfo{}} = MainSocket.get_symbol(pid, query)
    end

    test "get tick prices", %{pid: pid} do
      args = %{
        level: 0,
        symbols: ["LITECOIN"],
        timestamp: DateTime.add(DateTime.utc_now(), -2 * 60)
      }

      query = TickPrices.Query.new(args)

      assert {:ok, %TickPrices{data: data}} = MainSocket.get_tick_prices(pid, query)
      assert [elem | _] = data
      assert %TickPrice{} = elem
    end

    test "get trades history", %{pid: pid} do
      args = %{
        from: DateTime.add(DateTime.utc_now(), -3 * 31 * 24 * 60 * 60),
        to: DateTime.utc_now()
      }

      query = DateRange.new(args)

      assert {:ok, %TradeInfos{data: data}} = MainSocket.get_trades_history(pid, query)
      assert [elem | _] = data
      assert %TradeInfo{} = elem
    end

    test "get trading hours", %{pid: pid} do
      args = ["EURPLN", "AGO.PL_9"]
      query = TradingHours.Query.new(args)

      assert {:ok, %TradingHours{data: data}} = MainSocket.get_trading_hours(pid, query)
      assert [elem | _] = data
      assert %TradingHour{} = elem
      assert [qu | _] = elem.quotes
      assert [trading | _] = elem.trading
      assert %Quote{} = qu
      assert %Quote{} = trading
    end

    test "get version", %{pid: pid} do
      assert {:ok, %Version{}} = MainSocket.get_version(pid)
    end
  end

  @default_wait_time 60 * 1000

  describe "trade transaction with async messages" do
    setup :setup_main_socket

    setup %{pid: pid, params: params} do
      {:ok, _store} = start_supervised(StreamingTestStoreMock)

      parent_pid = self()
      Agent.update(StreamingTestStoreMock, fn _ -> %{parent_pid: parent_pid} end)

      {:ok, stream_session_id} = poll_stream_session_id(pid)

      params =
        Keyword.merge(params, stream_session_id: stream_session_id, module: StreamingSocketMock)

      {:ok, streaming_pid} = StreamingSocket.start_link(params)
      assert {:ok, _} = StreamingSocket.subscribe_get_trade_status(streaming_pid)

      :ok
    end

    test "trade transaction - open and close transaction", %{pid: pid} do
      buy_args = %{
        operation: :buy,
        custom_comment: "Buy transaction",
        price: 1200.0,
        symbol: "LITECOIN",
        type: :open,
        volume: 1.0
      }

      buy = TradeTransaction.Command.new(buy_args)

      assert {:ok, %TradeTransaction{order: open_order_id}} =
               MainSocket.trade_transaction(pid, buy)

      assert_receive {:ok, %TradeStatus{}}, @default_wait_time

      status = TradeTransactionStatus.Query.new(open_order_id)
      assert {:ok, %TradeTransactionStatus{}} = MainSocket.trade_transaction_status(pid, status)

      # get all opened only trades
      trades_query = Trades.Query.new(true)
      assert {:ok, %TradeInfos{data: data}} = MainSocket.get_trades(pid, trades_query)

      position_to_close =
        Enum.find(
          data,
          &(&1.order_closed == open_order_id)
        )

      close_args = %{
        operation: :buy,
        custom_comment: "Close transaction",
        price: position_to_close.open_price - 0.01,
        symbol: "LITECOIN",
        order: position_to_close.order_opened,
        type: :close,
        volume: 1.0
      }

      close = TradeTransaction.Command.new(close_args)

      assert {:ok, %TradeTransaction{}} = MainSocket.trade_transaction(pid, close)
      assert_receive {:ok, %TradeStatus{order: close_order_id}}, @default_wait_time

      status = TradeTransactionStatus.Query.new(close_order_id)

      assert {:ok, %TradeTransactionStatus{status: :accepted}} =
               MainSocket.trade_transaction_status(pid, status)
    end
  end

  defp setup_main_socket(%{params: params} = _context) do
    {:ok, pid} = start_supervised({MainSocket, params})

    {:ok, %{pid: pid}}
  end
end
