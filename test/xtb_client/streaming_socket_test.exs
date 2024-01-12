defmodule XtbClient.StreamingSocketTest do
  @moduledoc false
  use ExUnit.Case
  doctest XtbClient.StreamingSocket

  alias XtbClient.MainSocket
  alias XtbClient.Messages
  alias XtbClient.StreamingSocket
  alias XtbClient.StreamingSocketMock
  alias XtbClient.StreamingTestStoreMock

  import XtbClient.MainSocket.E2EFixtures

  @default_wait_time 60 * 1000

  setup do
    Dotenvy.source([
      ".env.#{Mix.env()}",
      ".env.#{Mix.env()}.override",
      System.get_env()
    ])

    url = Dotenvy.env!("XTB_API_URL", :string!)
    user = Dotenvy.env!("XTB_API_USERNAME", :string!)
    passwd = Dotenvy.env!("XTB_API_PASSWORD", :string!)
    type = :demo

    params = [
      url: url,
      type: :demo,
      user: user,
      password: passwd,
      app_name: "XtbClient"
    ]

    {:ok, pid} = start_supervised({MainSocket, params})
    {:ok, stream_session_id} = poll_stream_session_id(pid)

    {:ok,
     %{
       params: [
         url: url,
         type: type,
         stream_session_id: stream_session_id,
         module: StreamingSocketMock
       ],
       main: pid
     }}
  end

  describe "session management" do
    @tag timeout: 40 * 1000
    test "sends ping after login", %{params: params} do
      {:ok, pid} = StreamingSocket.start_link(params)

      Process.sleep(30 * 1000 + 1)

      assert Process.alive?(pid) == true
    end

    test "can be managed by dynamic supervisor", %{params: params} do
      {:ok, _} =
        DynamicSupervisor.start_link(
          strategy: :one_for_one,
          name: XtbClient.StreamingDynamicSupervisor
        )

      {:ok, pid} =
        DynamicSupervisor.start_child(
          XtbClient.StreamingDynamicSupervisor,
          {StreamingSocket, params}
        )

      assert Process.alive?(pid) == true
      assert Process.exit(pid, :kill) == true

      Process.sleep(100)

      assert [{:undefined, _, :worker, [StreamingSocket]}] =
               DynamicSupervisor.which_children(XtbClient.StreamingDynamicSupervisor)
    end

    test "handles additional params to start_link/2", %{params: params} do
      params = Keyword.merge(params, name: StreamingSocketTest)
      {:ok, pid} = StreamingSocket.start_link(params)

      assert Process.whereis(StreamingSocketTest) == pid
    end
  end

  describe "public API" do
    setup context do
      {:ok, pid} = start_supervised({StreamingSocket, context.params})

      {:ok, _store} = start_supervised(StreamingTestStoreMock)

      parent_pid = self()
      Agent.update(StreamingTestStoreMock, fn _ -> %{parent_pid: parent_pid} end)

      {:ok, %{pid: pid}}
    end

    test "subscribe to get balance", %{pid: pid, main: main} do
      assert {:ok, _} = StreamingSocket.subscribe_get_balance(pid)

      buy_args = %{
        operation: :buy,
        custom_comment: "Buy transaction",
        price: 1200.0,
        symbol: "LITECOIN",
        type: :open,
        volume: 1.0
      }

      {:ok, %{order: order_id}} = open_trade(main, buy_args)

      assert_receive {:ok, %Messages.BalanceInfo{}}, @default_wait_time

      close_args = %{
        operation: :buy,
        custom_comment: "Close transaction",
        symbol: "LITECOIN",
        type: :close,
        volume: 1.0
      }

      {:ok, _} = close_trade(main, order_id, close_args)

      assert_receive {:ok, %Messages.BalanceInfo{}}, @default_wait_time
    end

    test "unsubscribe from get balance", %{pid: pid, main: main} do
      assert {:ok, _} = StreamingSocket.subscribe_get_balance(pid)

      buy_args = %{
        operation: :buy,
        custom_comment: "Buy transaction",
        price: 1200.0,
        symbol: "LITECOIN",
        type: :open,
        volume: 1.0
      }

      {:ok, %{order: order_id}} = open_trade(main, buy_args)

      assert_receive {:ok, %Messages.BalanceInfo{}}, @default_wait_time

      assert {:ok, _} = StreamingSocket.unsubscribe_get_balance(pid)

      close_args = %{
        operation: :buy,
        custom_comment: "Close transaction",
        symbol: "LITECOIN",
        type: :close,
        volume: 1.0
      }

      {:ok, _} = close_trade(main, order_id, close_args)

      refute_receive {:ok, %Messages.BalanceInfo{}}, 100
    end

    @tag timeout: @default_wait_time
    test "subscribe to get candles", %{pid: pid} do
      args = "LITECOIN"
      query = Messages.Candles.Query.new(args)
      assert {:ok, _} = StreamingSocket.subscribe_get_candles(pid, query)

      assert_receive {:ok, %Messages.Candle{}}, @default_wait_time
    end

    @tag timeout: @default_wait_time * 2
    test "unsubscribe from get candles", %{pid: pid} do
      args = "LITECOIN"
      query = Messages.Candles.Query.new(args)
      assert {:ok, _} = StreamingSocket.subscribe_get_candles(pid, query)

      assert_receive {:ok, %Messages.Candle{}}, @default_wait_time

      # wait for already received messages
      flush()

      assert {:ok, _} = StreamingSocket.unsubscribe_get_candles(pid, query)

      refute_receive {:ok, %Messages.Candle{}}, 100
    end

    test "subscribe to keep alive", %{pid: pid} do
      assert {:ok, _} = StreamingSocket.subscribe_keep_alive(pid)

      assert_receive {:ok, %Messages.KeepAlive{}}, @default_wait_time
    end

    test "unsubscribe from keep alive", %{pid: pid} do
      assert {:ok, _} = StreamingSocket.subscribe_keep_alive(pid)

      assert_receive {:ok, %Messages.KeepAlive{}}, @default_wait_time

      # wait for already received messages
      flush()

      assert {:ok, _} = StreamingSocket.unsubscribe_keep_alive(pid)

      refute_receive {:ok, %Messages.KeepAlive{}}, 100
    end

    @tag skip: true
    test "subscribe to get news", %{pid: pid} do
      assert {:ok, _} = StreamingSocket.subscribe_get_news(pid)

      assert_receive {:ok, %Messages.NewsInfo{}}, @default_wait_time
    end

    @tag skip: true
    test "unsubscribe from get news", %{pid: pid} do
      assert {:ok, _} = StreamingSocket.subscribe_get_news(pid)

      assert_receive {:ok, %Messages.NewsInfo{}}, @default_wait_time

      # wait for already received messages
      flush()

      assert {:ok, _} = StreamingSocket.unsubscribe_get_news(pid)

      refute_receive {:ok, %Messages.NewsInfo{}}, 100
    end

    test "subscribe to get profits", %{pid: pid, main: main} do
      assert {:ok, _} = StreamingSocket.subscribe_get_profits(pid)

      buy_args = %{
        operation: :buy,
        custom_comment: "Buy transaction",
        price: 1200.0,
        symbol: "LITECOIN",
        type: :open,
        volume: 1.0
      }

      {:ok, %{order: order_id}} = open_trade(main, buy_args)

      assert_receive {:ok, %Messages.ProfitInfo{}}, @default_wait_time

      close_args = %{
        operation: :buy,
        custom_comment: "Close transaction",
        symbol: "LITECOIN",
        type: :close,
        volume: 1.0
      }

      {:ok, _} = close_trade(main, order_id, close_args)

      assert_receive {:ok, %Messages.ProfitInfo{}}, @default_wait_time
    end

    test "unsubscribe from get profits", %{pid: pid, main: main} do
      assert {:ok, _} = StreamingSocket.subscribe_get_profits(pid)

      buy_args = %{
        operation: :buy,
        custom_comment: "Buy transaction",
        price: 1200.0,
        symbol: "LITECOIN",
        type: :open,
        volume: 1.0
      }

      {:ok, %{order: order_id}} = open_trade(main, buy_args)

      assert_receive {:ok, %Messages.ProfitInfo{}}, @default_wait_time

      assert {:ok, _} = StreamingSocket.unsubscribe_get_profits(pid)

      close_args = %{
        operation: :buy,
        custom_comment: "Close transaction",
        symbol: "LITECOIN",
        type: :close,
        volume: 1.0
      }

      {:ok, _} = close_trade(main, order_id, close_args)

      refute_receive {:ok, %Messages.ProfitInfo{}}, 100
    end

    test "subscribe to get tick prices", %{pid: pid} do
      args = %{symbol: "LITECOIN"}
      query = Messages.Quotations.Query.new(args)
      assert {:ok, _} = StreamingSocket.subscribe_get_tick_prices(pid, query)

      assert_receive {:ok, %Messages.TickPrice{}}, @default_wait_time
    end

    test "unsubscribe from get tick prices", %{pid: pid} do
      args = %{symbol: "LITECOIN"}
      query = Messages.Quotations.Query.new(args)
      assert {:ok, _} = StreamingSocket.subscribe_get_tick_prices(pid, query)

      assert_receive {:ok, %Messages.TickPrice{}}, @default_wait_time

      # wait for already received messages
      flush()

      assert {:ok, _} = StreamingSocket.unsubscribe_get_tick_prices(pid, query)

      refute_receive {:ok, %Messages.TickPrice{}}, 100
    end

    test "subscribe to get trades", %{pid: pid, main: main} do
      assert {:ok, _} = StreamingSocket.subscribe_get_trades(pid)

      buy_args = %{
        operation: :buy,
        custom_comment: "Buy transaction",
        price: 1200.0,
        symbol: "LITECOIN",
        type: :open,
        volume: 1.0
      }

      {:ok, %{order: order_id}} = open_trade(main, buy_args)

      assert_receive {:ok, %Messages.TradeInfo{operation: :buy}},
                     @default_wait_time

      close_args = %{
        operation: :buy,
        custom_comment: "Close transaction",
        symbol: "LITECOIN",
        type: :close,
        volume: 1.0
      }

      {:ok, _} = close_trade(main, order_id, close_args)

      assert_receive {:ok, %Messages.TradeInfo{operation: :sell}}, @default_wait_time
    end

    test "unsubscribe from get trades", %{pid: pid, main: main} do
      assert {:ok, _} = StreamingSocket.subscribe_get_trades(pid)

      buy_args = %{
        operation: :buy,
        custom_comment: "Buy transaction",
        price: 1200.0,
        symbol: "LITECOIN",
        type: :open,
        volume: 1.0
      }

      {:ok, %{order: order_id}} = open_trade(main, buy_args)

      assert_receive {:ok, %Messages.TradeInfo{operation: :buy}},
                     @default_wait_time

      assert {:ok, _} = StreamingSocket.unsubscribe_get_trades(pid)

      close_args = %{
        operation: :buy,
        custom_comment: "Close transaction",
        symbol: "LITECOIN",
        type: :close,
        volume: 1.0
      }

      {:ok, _} = close_trade(main, order_id, close_args)

      refute_receive {:ok, %Messages.TradeInfo{operation: :sell}}, 100
    end

    test "subscribe to trade status", %{pid: pid, main: main} do
      assert {:ok, _} = StreamingSocket.subscribe_get_trade_status(pid)

      buy_args = %{
        operation: :buy,
        custom_comment: "Buy transaction",
        price: 1200.0,
        symbol: "LITECOIN",
        type: :open,
        volume: 1.0
      }

      {:ok, %{order: order_id}} = open_trade(main, buy_args)

      assert_receive {:ok, %Messages.TradeStatus{}}, @default_wait_time

      close_args = %{
        operation: :buy,
        custom_comment: "Close transaction",
        symbol: "LITECOIN",
        type: :close,
        volume: 1.0
      }

      {:ok, _} = close_trade(main, order_id, close_args)

      assert_receive {:ok, %Messages.TradeStatus{}}, @default_wait_time
    end

    test "unsubscribe from trade status", %{pid: pid, main: main} do
      assert {:ok, _} = StreamingSocket.subscribe_get_trade_status(pid)

      buy_args = %{
        operation: :buy,
        custom_comment: "Buy transaction",
        price: 1200.0,
        symbol: "LITECOIN",
        type: :open,
        volume: 1.0
      }

      {:ok, %{order: order_id}} = open_trade(main, buy_args)

      assert_receive {:ok, %Messages.TradeStatus{}}, @default_wait_time

      assert {:ok, _} = StreamingSocket.unsubscribe_get_trade_status(pid)

      close_args = %{
        operation: :buy,
        custom_comment: "Close transaction",
        symbol: "LITECOIN",
        type: :close,
        volume: 1.0
      }

      {:ok, _} = close_trade(main, order_id, close_args)

      refute_receive {:ok, %Messages.TradeStatus{}}, 100
    end
  end

  defp flush do
    receive do
      _ -> flush()
    after
      10 -> :ok
    end
  end
end
