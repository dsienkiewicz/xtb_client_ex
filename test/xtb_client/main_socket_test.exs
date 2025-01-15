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
    TradeTransaction,
    TradeTransactionStatus,
    TradingHour,
    TradingHours,
    UserInfo,
    Version
  }

  setup do
    url = System.get_env("XTB_API_URL")
    user = System.get_env("XTB_API_USERNAME")
    passwd = System.get_env("XTB_API_PASSWORD")

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
      {:ok, stream_session_id} = MainSocket.stream_session_id(pid)
      assert is_binary(stream_session_id)
    end

    @tag timeout: 40 * 1000
    test "sends ping after login", %{pid: pid} do
      Process.sleep(30 * 1000 + 1)

      assert Process.alive?(pid) == true
    end

    test "get all symbols", %{pid: pid} do
      assert {:ok, %SymbolInfos{data: data}} =
               MainSocket.handle_query(pid, SymbolInfos.Query.new())

      assert [elem | _] = data
      assert %SymbolInfo{} = elem
    end

    test "get calendar", %{pid: pid} do
      assert {:ok, %CalendarInfos{data: data}} =
               MainSocket.handle_query(pid, CalendarInfos.Query.new())

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

      assert {:ok, %RateInfos{data: data, digits: digits}} = MainSocket.handle_query(pid, query)
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
               MainSocket.handle_query(pid, query)

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
      query =
        %{symbol: "EURPLN", volume: 1}
        |> SymbolVolume.new()
        |> CommissionDefinition.Query.new()

      assert {:ok, %CommissionDefinition{}} = MainSocket.handle_query(pid, query)
    end

    test "get current user data", %{pid: pid} do
      assert {:ok, %UserInfo{}} = MainSocket.handle_query(pid, UserInfo.Query.new())
    end

    test "get margin level", %{pid: pid} do
      assert {:ok, %BalanceInfo{}} =
               MainSocket.handle_query(pid, BalanceInfo.MarginLevelQuery.new())
    end

    test "get margin trade", %{pid: pid} do
      query =
        %{symbol: "EURPLN", volume: 1}
        |> SymbolVolume.new()
        |> MarginTrade.Query.new()

      assert {:ok, %MarginTrade{}} = MainSocket.handle_query(pid, query)
    end

    test "get news", %{pid: pid} do
      query =
        %{
          from: DateTime.add(DateTime.utc_now(), -2 * 30 * 24 * 60 * 60),
          to: DateTime.utc_now()
        }
        |> DateRange.new()
        |> NewsInfos.Query.new()

      assert {:ok, %NewsInfos{data: data}} = MainSocket.handle_query(pid, query)
      assert [elem | _] = data
      assert %NewsInfo{} = elem
    end

    test "get profit calculation", %{pid: pid} do
      query =
        ProfitCalculation.Query.new(%{
          open_price: 1.2233,
          close_price: 1.3,
          operation: :buy,
          symbol: "EURPLN",
          volume: 1.0
        })

      assert {:ok, %ProfitCalculation{}} = MainSocket.handle_query(pid, query)
    end

    test "get server time", %{pid: pid} do
      assert {:ok, %ServerTime{}} = MainSocket.handle_query(pid, ServerTime.Query.new())
    end

    test "get step rules", %{pid: pid} do
      assert {:ok, %StepRules{data: data}} = MainSocket.handle_query(pid, StepRules.Query.new())
      assert [elem | _] = data
      assert %StepRule{steps: [step | _]} = elem
      assert %Step{} = step
    end

    test "get symbol", %{pid: pid} do
      query = SymbolInfo.Query.new("BHW.PL_9")

      assert {:ok, %SymbolInfo{}} = MainSocket.handle_query(pid, query)
    end

    test "get tick prices", %{pid: pid} do
      query =
        TickPrices.Query.new(%{
          level: 0,
          symbols: ["LITECOIN"],
          timestamp: DateTime.add(DateTime.utc_now(), -2 * 60)
        })

      assert {:ok, %TickPrices{data: data}} = MainSocket.handle_query(pid, query)
      assert [elem | _] = data
      assert %TickPrice{} = elem
    end

    test "get trades history", %{pid: pid} do
      query =
        %{
          from: DateTime.add(DateTime.utc_now(), -3 * 31 * 24 * 60 * 60),
          to: DateTime.utc_now()
        }
        |> DateRange.new()
        |> Trades.TradesHistoryQuery.new()

      assert {:ok, %TradeInfos{data: data}} = MainSocket.handle_query(pid, query)
      assert [elem | _] = data
      assert %TradeInfo{} = elem
    end

    test "get trading hours", %{pid: pid} do
      query = TradingHours.Query.new(["EURPLN", "AGO.PL_9"])

      assert {:ok, %TradingHours{data: data}} = MainSocket.handle_query(pid, query)
      assert [elem | _] = data
      assert %TradingHour{} = elem
      assert [qu | _] = elem.quotes
      assert [trading | _] = elem.trading
      assert %Quote{} = qu
      assert %Quote{} = trading
    end

    test "get version", %{pid: pid} do
      assert {:ok, %Version{}} = MainSocket.handle_query(pid, Version.Query.new())
    end

    test "trade transaction - open and close transaction", %{pid: pid} do
      buy_command =
        %{
          operation: :buy,
          price: 9999.0,
          symbol: "LITECOIN",
          type: :open,
          volume: 1.0
        }
        |> TradeTransaction.Command.new()
        |> TradeTransaction.Command.custom_comment("Buy transaction")

      assert {:ok, %TradeTransaction{order: open_order_id}} =
               MainSocket.handle_query(pid, buy_command)

      status_query = TradeTransactionStatus.Query.new(open_order_id)
      assert {:ok, %TradeTransactionStatus{}} = MainSocket.handle_query(pid, status_query)

      # get trade records
      # trade_records_query = TradeInfos.Query.new([open_order_id])
      # assert {:ok, %TradeInfos{data: data}} = MainSocket.handle_query(pid, trade_records_query)
      # assert [elem | _] = data
      # assert %TradeInfo{} = elem

      # get trades (opened only)
      trades_query = Trades.TradesQuery.new(true)
      assert {:ok, %TradeInfos{data: data}} = MainSocket.handle_query(pid, trades_query)

      position_to_close =
        Enum.find(
          data,
          &(&1.order_closed == open_order_id)
        )

      close_command =
        %{
          operation: :buy,
          price: position_to_close.open_price - 0.01,
          symbol: "LITECOIN",
          type: :close,
          volume: position_to_close.volume
        }
        |> TradeTransaction.Command.new()
        |> TradeTransaction.Command.order(position_to_close.order_opened)
        |> TradeTransaction.Command.custom_comment("Close transaction")

      assert {:ok, %TradeTransaction{order: close_order_id}} =
               MainSocket.handle_query(pid, close_command)

      status_query = TradeTransactionStatus.Query.new(close_order_id)

      assert {:ok, %TradeTransactionStatus{status: :accepted}} =
               MainSocket.handle_query(pid, status_query)
    end
  end

  defp setup_main_socket(%{params: params} = _context) do
    {:ok, pid} = start_supervised({MainSocket, params})

    {:ok, %{pid: pid}}
  end
end
