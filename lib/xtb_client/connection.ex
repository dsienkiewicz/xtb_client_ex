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
  
  ## Example of synchronous call
  
  ```
  params = %{app_name: "XtbClient", type: :demo, url: "wss://ws.xtb.com", user: "<<USER_ID>>", password: "<<PASSWORD>>"}
  {:ok, pid} = XtbClient.Connection.start_link(params)
  
  version = XtbClient.Connection.get_version(pid)
  # expect to see the actual version of the backend server
  ```
  
  Asynchronous operations, mainly `subscribe_` functions, returns immediately and stores the `pid` of the subscriber, so later it can send the message there.
  Note that each `subscribe_` function expects the `subscriber` as an argument, so `XtbClient.Connection` could serve different types
  of events to different subscribers. Only limitation is that each `subscribe_` function handles only one subscriber.
  
  ## Example of asynchronous call
  
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
  Returns chart info from start date to the current time.
  
  If the chosen period of `XtbClient.Messages.ChartLast.Query` is greater than 1 minute, the last candle returned by the API can change until the end of the period (the candle is being automatically updated every minute).
  
  Limitations: there are limitations in charts data availability. Detailed ranges for charts data, what can be accessed with specific period, are as follows:
  
  - PERIOD_M1 --- <0-1) month, i.e. one month time
  - PERIOD_M30 --- <1-7) month, six months time
  - PERIOD_H4 --- <7-13) month, six months time
  - PERIOD_D1 --- 13 month, and earlier on
  
  Note, that specific PERIOD_ is the lowest (i.e. the most detailed) period, accessible in listed range. For instance, in months range <1-7) you can access periods: PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1.
  Specific data ranges availability is guaranteed, however those ranges may be wider, e.g.: PERIOD_M1 may be accessible for 1.5 months back from now, where 1.0 months is guaranteed.
  
  ## Example scenario:
  
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
  @spec get_chart_range(client(), XtbClient.Messages.ChartRange.Query.t()) ::
          XtbClient.Messages.RateInfos.t()
  def get_chart_range(pid, %ChartRange.Query{} = params) do
    GenServer.call(pid, {"getChartRangeRequest", %{info: params}})
  end

  @doc """
  Returns calculation of commission and rate of exchange.
  
  The value is calculated as expected value and therefore might not be perfectly accurate.
  """
  @spec get_commission_def(client(), XtbClient.Messages.SymbolVolume.t()) ::
          XtbClient.Messages.CommissionDefinition.t()
  def get_commission_def(pid, %SymbolVolume{} = params) do
    GenServer.call(pid, {"getCommissionDef", params})
  end

  @doc """
  Returns information about account currency and account leverage.
  """
  @spec get_current_user_data(client()) :: XtbClient.Messages.UserInfo.t()
  def get_current_user_data(pid) do
    GenServer.call(pid, {"getCurrentUserData"})
  end

  @doc """
  Returns IBs data from the given time range.
  """
  @spec get_ibs_history(client(), XtbClient.Messages.DateRange.t()) :: any()
  def get_ibs_history(pid, %DateRange{} = params) do
    GenServer.call(pid, {"getIbsHistory", params})
  end

  @doc """
  Returns various account indicators.
  
  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_balance/2` which is the preferred way of retrieving current account indicators.**
  """
  @spec get_margin_level(client()) :: XtbClient.Messages.BalanceInfo.t()
  def get_margin_level(pid) do
    GenServer.call(pid, {"getMarginLevel"})
  end

  @doc """
  Returns expected margin for given instrument and volume.
  
  The value is calculated as expected margin value and therefore might not be perfectly accurate.
  """
  @spec get_margin_trade(client(), XtbClient.Messages.SymbolVolume.t()) ::
          XtbClient.Messages.MarginTrade.t()
  def get_margin_trade(pid, %SymbolVolume{} = params) do
    GenServer.call(pid, {"getMarginTrade", params})
  end

  @doc """
  Returns news from trading server which were sent within specified period of time.
  
  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_news/2` which is the preferred way of retrieving news data.**
  """
  @spec get_news(client(), XtbClient.Messages.DateRange.t()) :: XtbClient.Messages.NewsInfos.t()
  def get_news(pid, %DateRange{} = params) do
    GenServer.call(pid, {"getNews", params})
  end

  @doc """
  Calculates estimated profit for given deal data.
  
  Should be used for calculator-like apps only.
  Profit for opened transactions should be taken from server, due to higher precision of server calculation.
  """
  @spec get_profit_calculation(client(), XtbClient.Messages.ProfitCalculation.Query.t()) ::
          XtbClient.Messages.ProfitCalculation.t()
  def get_profit_calculation(pid, %ProfitCalculation.Query{} = params) do
    GenServer.call(pid, {"getProfitCalculation", params})
  end

  @doc """
  Returns current time on trading server.
  """
  @spec get_server_time(client()) :: XtbClient.Messages.ServerTime.t()
  def get_server_time(pid) do
    GenServer.call(pid, {"getServerTime"})
  end

  @doc """
  Returns a list of step rules for DMAs.
  """
  @spec get_step_rules(client()) :: XtbClient.Messages.StepRules.t()
  def get_step_rules(pid) do
    GenServer.call(pid, {"getStepRules"})
  end

  @doc """
  Returns information about symbol available for the user.
  """
  @spec get_symbol(client(), XtbClient.Messages.SymbolInfo.Query.t()) ::
          XtbClient.Messages.SymbolInfo.t()
  def get_symbol(pid, %SymbolInfo.Query{} = params) do
    GenServer.call(pid, {"getSymbol", params})
  end

  @doc """
  Returns array of current quotations for given symbols, only quotations that changed from given timestamp are returned.
  
  New timestamp obtained from output will be used as an argument of the next call of this command.
  
  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_tick_prices/3` which is the preferred way of retrieving ticks data.**
  """
  @spec get_tick_prices(client(), XtbClient.Messages.TickPrices.Query.t()) ::
          XtbClient.Messages.TickPrices.t()
  def get_tick_prices(pid, %TickPrices.Query{} = params) do
    GenServer.call(pid, {"getTickPrices", params})
  end

  @doc """
  Returns array of trades listed in orders query.
  """
  @spec get_trade_records(client(), XtbClient.Messages.TradeInfos.Query.t()) ::
          XtbClient.Messages.TradeInfos.t()
  def get_trade_records(pid, %TradeInfos.Query{} = params) do
    GenServer.call(pid, {"getTradeRecords", params})
  end

  @doc """
  Returns array of user's trades.
  
  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_trades/2` which is the preferred way of retrieving trades data.**
  """
  @spec get_trades(client(), XtbClient.Messages.Trades.Query.t()) ::
          XtbClient.Messages.TradeInfos.t()
  def get_trades(pid, %Trades.Query{} = params) do
    GenServer.call(pid, {"getTrades", params})
  end

  @doc """
  Returns array of user's trades which were closed within specified period of time.
  """
  @spec get_trades_history(client(), XtbClient.Messages.DateRange.t()) ::
          XtbClient.Messages.TradeInfos.t()
  def get_trades_history(pid, %DateRange{} = params) do
    GenServer.call(pid, {"getTradesHistory", params})
  end

  @doc """
  Returns quotes and trading times.
  """
  @spec get_trading_hours(client(), XtbClient.Messages.TradingHours.Query.t()) ::
          XtbClient.Messages.TradingHours.t()
  def get_trading_hours(pid, %TradingHours.Query{} = params) do
    GenServer.call(pid, {"getTradingHours", params})
  end

  @doc """
  Returns the current API version.
  """
  @spec get_version(client()) :: XtbClient.Messages.Version.t()
  def get_version(pid) do
    GenServer.call(pid, {"getVersion"})
  end

  @doc """
  Starts trade transaction.
  
  `trade_transaction/2` sends main transaction information to the server.
  
  ## How to verify that the trade request was accepted?
  The status field set to 'true' does not imply that the transaction was accepted. It only means, that the server acquired your request and began to process it.
  To analyse the status of the transaction (for example to verify if it was accepted or rejected) use the `trade_transaction_status/2` command with the order number that came back with the response of the `trade_transaction/2` command.
  """
  @spec trade_transaction(client(), XtbClient.Messages.TradeTransaction.Command.t()) ::
          XtbClient.Messages.TradeTransaction.t()
  def trade_transaction(pid, %TradeTransaction.Command{} = params) do
    GenServer.call(pid, {"tradeTransaction", %{tradeTransInfo: params}})
  end

  @doc """
  Returns current transaction status.
  
  At any time of transaction processing client might check the status of transaction on server side.
  In order to do that client must provide unique order taken from `trade_transaction/2` invocation.
  """
  @spec trade_transaction_status(client(), XtbClient.Messages.TradeTransactionStatus.Query.t()) ::
          XtbClient.Messages.TradeTransactionStatus.t()
  def trade_transaction_status(pid, %TradeTransactionStatus.Query{} = params) do
    GenServer.call(pid, {"tradeTransactionStatus", params})
  end

  def subscribe_get_balance(pid, subscriber) do
    ref = inspect(make_ref())
    GenServer.cast(pid, {:subscribe, "getBalance", "balance", {subscriber, ref}})
  end

  def subscribe_get_candles(pid, subscriber, %Candles.Query{} = params) do
    ref = inspect(make_ref())
    GenServer.cast(pid, {:subscribe, "getCandles", "candle", {subscriber, ref}, params})
  end

  def subscribe_keep_alive(pid, subscriber) do
    ref = inspect(make_ref())
    GenServer.cast(pid, {:subscribe, "getKeepAlive", "keepAlive", {subscriber, ref}})
  end

  def subscribe_get_news(pid, subscriber) do
    ref = inspect(make_ref())
    GenServer.cast(pid, {:subscribe, "getNews", "news", {subscriber, ref}})
  end

  def subscribe_get_profits(pid, subscriber) do
    ref = inspect(make_ref())
    GenServer.cast(pid, {:subscribe, "getProfits", "profit", {subscriber, ref}})
  end

  def subscribe_get_tick_prices(pid, subscriber, %Quotations.Query{} = params) do
    ref = inspect(make_ref())

    GenServer.cast(
      pid,
      {:subscribe, "getTickPrices", "tickPrices", {subscriber, ref}, params}
    )
  end

  def subscribe_get_trades(pid, subscriber) do
    ref = inspect(make_ref())
    GenServer.cast(pid, {:subscribe, "getTrades", "trade", {subscriber, ref}})
  end

  def subscribe_get_trade_status(pid, subscriber) do
    ref = inspect(make_ref())
    GenServer.cast(pid, {:subscribe, "getTradeStatus", "tradeStatus", {subscriber, ref}})
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
        {:subscribe, method, response_method, {subscriber, ref}} = _message,
        %{spid: spid, subscribers: subscribers} = state
      ) do
    StreamingSocket.subscribe(spid, self(), response_method, {method, ref})

    subscribers = Map.put(subscribers, {method, ref}, subscriber)
    state = %{state | subscribers: subscribers}

    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:subscribe, method, response_method, {subscriber, ref}, params} = _message,
        %{spid: spid, subscribers: subscribers} = state
      ) do
    StreamingSocket.subscribe(spid, self(), response_method, {method, ref}, params)

    subscribers = Map.put(subscribers, {method, ref}, subscriber)
    state = %{state | subscribers: subscribers}

    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:stream, {method, ref}, result} = _message,
        %{subscribers: subscribers} = state
      ) do
    subscriber = Map.get(subscribers, {method, ref})
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
