defmodule XtbClient.Connection do
  use GenServer

  alias XtbClient.{MainSocket, StreamingSocket}

  alias XtbClient.Messages.{
    Candles,
    ChartLast,
    ChartRange,
    DateRange,
    ProfitCalculation,
    Quotations,
    SymbolInfo,
    SymbolVolume,
    TickPrices,
    TradeInfos,
    Trades,
    TradeTransaction,
    TradeTransactionStatus,
    TradingHours
  }

  require Logger

  @type client :: atom | pid | {atom, any} | {:via, atom, any}

  @moduledoc """
  `GenServer` which handles all commands and queries issued to XTB platform.
  
  Acts as a proxy process between the client and the underlying main and streaming socket.
  
  After successful initialization the process should hold references to both `XtbClient.MainSocket` and `XtbClient.StreamingSocket` processes,
  so it can mediate all commands and queries from the caller to the connected socket.
  
  For the synchronous operations clients should expect to get results as the function returned value.
  Example of synchronous call:
  
  ```
  params = %{app_name: "XtbClient", type: :demo, url: "wss://ws.xtb.com", user: "<<USER_ID>>", password: "<<PASSWORD>>"}
  {:ok, pid} = XtbClient.Connection.start_link(params)
  
  version = XtbClient.Connection.get_version(pid)
  # expect to see the actual version of the backend server
  ```
  
  Asynchronous operations, mainly `subscribe_` functions, returns immediately and stores the `pid` of the subscriber, so later it can send the message there.
  Note that each `subscribe_` function expects the `subscriber` as an argument, so `XtbClient.Connection` could serve different types
  of events to different subscribers. Only limitation is that each `subscribe_` function handles only one subscriber.
  Example of asynchronous call:
  
  ```
  defmodule StreamListener do
    use GenServer
  
    def start_link(args) do
      GenServer.start_link(__MODULE__, args, name: __MODULE__)
    end
  
    @impl true
    def init(state) do
      {:ok, state}
    end
  
    @impl true
    def handle_info(message, state) do
      IO.inspect(message, label: "Listener handle info")
      {:noreply, state}
    end
  end
  
  params = %{app_name: "XtbClient", type: :demo, url: "wss://ws.xtb.com", user: "<<USER_ID>>", password: "<<PASSWORD>>"}
  {:ok, cpid} = XtbClient.Connection.start_link(params)
  {:ok, lpid} = StreamListener.start_link(%{})
  
  args = %{symbol: "LITECOIN"}
  query = XtbClient.Messages.Quotations.Query.new(args)
  XtbClient.Connection.subscribe_get_tick_prices(cpid, lpid, query)
  # expect to see logs from StreamListener process with tick pricess logged
  ```
  """

  @doc """
  Starts a `XtbClient.Connection` process linked to the calling process.
  """
  @spec start_link(map) :: GenServer.on_start()
  def start_link(args) do
    state =
      args
      |> Map.put(:clients, %{})
      |> Map.put(:subscribers, %{})

    GenServer.start_link(__MODULE__, state, [])
  end

  @impl true
  def init(state) do
    {:ok, mpid} = MainSocket.start_link(state)
    Process.sleep(1_000)
    MainSocket.stream_session_id(mpid, self())

    Process.flag(:trap_exit, true)

    state =
      state
      |> Map.put(:mpid, mpid)
      |> Map.delete(:user)
      |> Map.delete(:password)

    {:ok, state}
  end

  @doc """
  Returns array of all symbols available for the user.
  """
  @spec get_all_symbols(client()) :: XtbClient.Messages.SymbolInfos.t()
  def get_all_symbols(pid) do
    GenServer.call(pid, {"getAllSymbols"})
  end

  @doc """
  Returns calendar with market events.
  """
  @spec get_calendar(client()) :: XtbClient.Messages.CalendarInfos.t()
  def get_calendar(pid) do
    GenServer.call(pid, {"getCalendar"})
  end

  @doc """
  Returns chart info, from start date to the current time.
  
  If the chosen period of `XtbClient.Messages.ChartLast.Query` is greater than 1 minute, the last candle returned by the API can change until the end of the period (the candle is being automatically updated every minute).
  
  Limitations: there are limitations in charts data availability. Detailed ranges for charts data, what can be accessed with specific period, are as follows:
  
  - PERIOD_M1 --- <0-1) month, i.e. one month time
  - PERIOD_M30 --- <1-7) month, six months time
  - PERIOD_H4 --- <7-13) month, six months time
  - PERIOD_D1 --- 13 month, and earlier on
  
  Note, that specific PERIOD_ is the lowest (i.e. the most detailed) period, accessible in listed range. For instance, in months range <1-7) you can access periods: PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1.
  Specific data ranges availability is guaranteed, however those ranges may be wider, e.g.: PERIOD_M1 may be accessible for 1.5 months back from now, where 1.0 months is guaranteed.
  
  Example scenario:
  
  * request charts of 5 minutes period, for 3 months time span, back from now;
  * response: you are guaranteed to get 1 month of 5 minutes charts; because, 5 minutes period charts are not accessible 2 months and 3 months back from now
  
  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_candles/3` which is the preferred way of retrieving current candle data.**
  """
  @spec get_chart_last(
          client(),
          XtbClient.Messages.ChartLast.Query.t()
        ) :: XtbClient.Messages.RateInfos.t()
  def get_chart_last(pid, %ChartLast.Query{} = params) do
    GenServer.call(pid, {"getChartLastRequest", %{info: params}})
  end

  @doc """
  Returns chart info with data between given start and end dates.
  
  Limitations: there are limitations in charts data availability. Detailed ranges for charts data, what can be accessed with specific period, are as follows:
  
  - PERIOD_M1 --- <0-1) month, i.e. one month time
  - PERIOD_M30 --- <1-7) month, six months time
  - PERIOD_H4 --- <7-13) month, six months time
  - PERIOD_D1 --- 13 month, and earlier on
  
  Note, that specific PERIOD_ is the lowest (i.e. the most detailed) period, accessible in listed range. For instance, in months range <1-7) you can access periods: PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1.
  Specific data ranges availability is guaranteed, however those ranges may be wider, e.g.: PERIOD_M1 may be accessible for 1.5 months back from now, where 1.0 months is guaranteed.
  
  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_candles/3` which is the preferred way of retrieving current candle data.**
  """
  def get_chart_range(pid, %ChartRange.Query{} = params) do
    GenServer.call(pid, {"getChartRangeRequest", %{info: params}})
  end

  def get_commission_def(pid, %SymbolVolume{} = params) do
    GenServer.call(pid, {"getCommissionDef", params})
  end

  def get_current_user_data(pid) do
    GenServer.call(pid, {"getCurrentUserData"})
  end

  def get_ibs_history(pid, %DateRange{} = params) do
    GenServer.call(pid, {"getIbsHistory", params})
  end

  def get_margin_level(pid) do
    GenServer.call(pid, {"getMarginLevel"})
  end

  def get_margin_trade(pid, %SymbolVolume{} = params) do
    GenServer.call(pid, {"getMarginTrade", params})
  end

  def get_news(pid, %DateRange{} = params) do
    GenServer.call(pid, {"getNews", params})
  end

  def get_profit_calculation(pid, %ProfitCalculation.Query{} = params) do
    GenServer.call(pid, {"getProfitCalculation", params})
  end

  def get_server_time(pid) do
    GenServer.call(pid, {"getServerTime"})
  end

  def get_step_rules(pid) do
    GenServer.call(pid, {"getStepRules"})
  end

  def get_symbol(pid, %SymbolInfo.Query{} = params) do
    GenServer.call(pid, {"getSymbol", params})
  end

  def get_tick_prices(pid, %TickPrices.Query{} = params) do
    GenServer.call(pid, {"getTickPrices", params})
  end

  def get_trade_records(pid, %TradeInfos.Query{} = params) do
    GenServer.call(pid, {"getTradeRecords", params})
  end

  def get_trades(pid, %Trades.Query{} = params) do
    GenServer.call(pid, {"getTrades", params})
  end

  def get_trades_history(pid, %DateRange{} = params) do
    GenServer.call(pid, {"getTradesHistory", params})
  end

  def get_trading_hours(pid, %TradingHours.Query{} = params) do
    GenServer.call(pid, {"getTradingHours", params})
  end

  def get_version(pid) do
    GenServer.call(pid, {"getVersion"})
  end

  def trade_transaction(pid, %TradeTransaction.Command{} = params) do
    GenServer.call(pid, {"tradeTransaction", %{tradeTransInfo: params}})
  end

  def trade_transaction_status(pid, %TradeTransactionStatus.Query{} = params) do
    GenServer.call(pid, {"tradeTransactionStatus", params})
  end

  def subscribe_get_balance(pid, subscriber) do
    GenServer.cast(pid, {:subscribe, "getBalance", "balance", subscriber})
  end

  def subscribe_get_candles(pid, subscriber, %Candles.Query{} = params) do
    GenServer.cast(pid, {:subscribe, "getCandles", "candle", subscriber, params})
  end

  def subscribe_keep_alive(pid, subscriber) do
    GenServer.cast(pid, {:subscribe, "getKeepAlive", "keepAlive", subscriber})
  end

  def subscribe_get_news(pid, subscriber) do
    GenServer.cast(pid, {:subscribe, "getNews", "news", subscriber})
  end

  def subscribe_get_profits(pid, subscriber) do
    GenServer.cast(pid, {:subscribe, "getProfits", "profit", subscriber})
  end

  def subscribe_get_tick_prices(pid, subscriber, %Quotations.Query{} = params) do
    GenServer.cast(pid, {:subscribe, "getTickPrices", "tickPrices", subscriber, params})
  end

  def subscribe_get_trades(pid, subscriber) do
    GenServer.cast(pid, {:subscribe, "getTrades", "trade", subscriber})
  end

  def subscribe_get_trade_status(pid, subscriber) do
    GenServer.cast(pid, {:subscribe, "getTradeStatus", "tradeStatus", subscriber})
  end

  @impl true
  def handle_call({method}, {_pid, ref} = from, %{mpid: mpid, clients: clients} = state) do
    ref_string = inspect(ref)
    MainSocket.query(mpid, self(), ref_string, method)

    clients = Map.put(clients, ref_string, from)
    state = %{state | clients: clients}

    {:noreply, state}
  end

  @impl true
  def handle_call({method, params}, {_pid, ref} = from, %{mpid: mpid, clients: clients} = state) do
    ref_string = inspect(ref)
    MainSocket.query(mpid, self(), ref_string, method, params)

    clients = Map.put(clients, ref_string, from)
    state = %{state | clients: clients}

    {:noreply, state}
  end

  @impl true
  def handle_cast({:response, ref, resp} = _message, %{clients: clients} = state) do
    {client, clients} = Map.pop!(clients, ref)
    GenServer.reply(client, resp)
    state = %{state | clients: clients}

    {:noreply, state}
  end

  @impl true
  def handle_cast({:stream_session_id, session_id} = _message, state) do
    args = Map.put(state, :stream_session_id, session_id)
    {:ok, spid} = StreamingSocket.start_link(args)

    state = Map.put(state, :spid, spid)

    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:subscribe, method, response_method, subscriber} = _message,
        %{spid: spid, subscribers: subscribers} = state
      ) do
    StreamingSocket.subscribe(spid, self(), response_method, method)

    subscribers = Map.put(subscribers, method, subscriber)
    state = %{state | subscribers: subscribers}

    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:subscribe, method, response_method, subscriber, params} = _message,
        %{spid: spid, subscribers: subscribers} = state
      ) do
    StreamingSocket.subscribe(spid, self(), response_method, method, params)

    subscribers = Map.put(subscribers, method, subscriber)
    state = %{state | subscribers: subscribers}

    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:stream, method, result} = _message,
        %{subscribers: subscribers} = state
      ) do
    subscriber = Map.get(subscribers, method)
    send(subscriber, {:ok, result})

    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, pid, reason}, state) do
    Logger.error(
      "Module handled exit message from #{inspect(pid)} with reason #{inspect(reason)}."
    )

    {:stop, :shutdown, state}
  end
end
