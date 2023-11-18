defmodule XtbClient.Connection do
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
      name = Map.get(args, "name") |> String.to_atom()
      GenServer.start_link(__MODULE__, args, name: name)
    end

    @impl true
    def init(state) do
      {:ok, state}
    end

    @impl true
    def handle_info(message, state) do
      IO.inspect({self(), message}, label: "Listener handle info")
      {:noreply, state}
    end
  end


  params = %{app_name: "XtbClient", type: :demo, url: "wss://ws.xtb.com", user: "<<USER_ID>>", password: "<<PASSWORD>>"}
  {:ok, cpid} = XtbClient.Connection.start_link(params)

  args = %{symbol: "LITECOIN"}
  query = XtbClient.Messages.Quotations.Query.new(args)
  {:ok, lpid} = StreamListener.start_link(%{"name" => args.symbol})
  XtbClient.Connection.subscribe_get_tick_prices(cpid, lpid, query)
  # expect to see logs from StreamListener process with tick pricess logged
  ```
  """
  use GenServer

  alias XtbClient.{MainSocket, StreamingSocket, StreamingMessage}

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

  defmodule State do
    @moduledoc false
    @enforce_keys [
      :type,
      :url,
      :clients,
      :subscribers
    ]
    defstruct type: nil,
              url: nil,
              mpid: nil,
              spid: nil,
              clients: %{},
              subscribers: %{},
              stream_session_id: nil
  end

  @doc """
  Starts a `XtbClient.Connection` process linked to the calling process.
  """
  @spec start_link(any(), GenServer.options()) :: GenServer.on_start()
  def start_link(_args, opts), do: start_link(opts)

  @doc """
  Starts a `XtbClient.Connection` process linked to the calling process.
  """
  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts) do
    {init_opts, conn_opts} = Keyword.split(opts, [:connection])
    GenServer.start_link(__MODULE__, init_opts, conn_opts)
  end

  @impl true
  def init(opts) do
    {:ok, mpid} = MainSocket.start_link(opts)

    Process.sleep(1_000)
    MainSocket.stream_session_id(mpid, self())

    Process.flag(:trap_exit, true)

    type = get_in(opts, [:type])
    url = get_in(opts, [:url])

    state = %State{
      mpid: mpid,
      spid: nil,
      type: type,
      url: url,
      clients: %{},
      subscribers: %{}
    }

    {:ok, state}
  end

  @doc """
  Returns array of all symbols available for the user.
  """
  @spec get_all_symbols(GenServer.server()) :: XtbClient.Messages.SymbolInfos.t()
  def get_all_symbols(pid) do
    GenServer.call(pid, {"getAllSymbols"})
  end

  @doc """
  Returns calendar with market events.
  """
  @spec get_calendar(GenServer.server()) :: XtbClient.Messages.CalendarInfos.t()
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
          GenServer.server(),
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
  @spec get_chart_range(GenServer.server(), XtbClient.Messages.ChartRange.Query.t()) ::
          XtbClient.Messages.RateInfos.t()
  def get_chart_range(pid, %ChartRange.Query{} = params) do
    GenServer.call(pid, {"getChartRangeRequest", %{info: params}})
  end

  @doc """
  Returns calculation of commission and rate of exchange.

  The value is calculated as expected value and therefore might not be perfectly accurate.
  """
  @spec get_commission_def(GenServer.server(), XtbClient.Messages.SymbolVolume.t()) ::
          XtbClient.Messages.CommissionDefinition.t()
  def get_commission_def(pid, %SymbolVolume{} = params) do
    GenServer.call(pid, {"getCommissionDef", params})
  end

  @doc """
  Returns information about account currency and account leverage.
  """
  @spec get_current_user_data(GenServer.server()) :: XtbClient.Messages.UserInfo.t()
  def get_current_user_data(pid) do
    GenServer.call(pid, {"getCurrentUserData"})
  end

  @doc """
  Returns IBs data from the given time range.
  """
  @spec get_ibs_history(GenServer.server(), XtbClient.Messages.DateRange.t()) :: any()
  def get_ibs_history(pid, %DateRange{} = params) do
    GenServer.call(pid, {"getIbsHistory", params})
  end

  @doc """
  Returns various account indicators.

  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_balance/2` which is the preferred way of retrieving current account indicators.**
  """
  @spec get_margin_level(GenServer.server()) :: XtbClient.Messages.BalanceInfo.t()
  def get_margin_level(pid) do
    GenServer.call(pid, {"getMarginLevel"})
  end

  @doc """
  Returns expected margin for given instrument and volume.

  The value is calculated as expected margin value and therefore might not be perfectly accurate.
  """
  @spec get_margin_trade(GenServer.server(), XtbClient.Messages.SymbolVolume.t()) ::
          XtbClient.Messages.MarginTrade.t()
  def get_margin_trade(pid, %SymbolVolume{} = params) do
    GenServer.call(pid, {"getMarginTrade", params})
  end

  @doc """
  Returns news from trading server which were sent within specified period of time.

  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_news/2` which is the preferred way of retrieving news data.**
  """
  @spec get_news(GenServer.server(), XtbClient.Messages.DateRange.t()) ::
          XtbClient.Messages.NewsInfos.t()
  def get_news(pid, %DateRange{} = params) do
    GenServer.call(pid, {"getNews", params})
  end

  @doc """
  Calculates estimated profit for given deal data.

  Should be used for calculator-like apps only.
  Profit for opened transactions should be taken from server, due to higher precision of server calculation.
  """
  @spec get_profit_calculation(GenServer.server(), XtbClient.Messages.ProfitCalculation.Query.t()) ::
          XtbClient.Messages.ProfitCalculation.t()
  def get_profit_calculation(pid, %ProfitCalculation.Query{} = params) do
    GenServer.call(pid, {"getProfitCalculation", params})
  end

  @doc """
  Returns current time on trading server.
  """
  @spec get_server_time(GenServer.server()) :: XtbClient.Messages.ServerTime.t()
  def get_server_time(pid) do
    GenServer.call(pid, {"getServerTime"})
  end

  @doc """
  Returns a list of step rules for DMAs.
  """
  @spec get_step_rules(GenServer.server()) :: XtbClient.Messages.StepRules.t()
  def get_step_rules(pid) do
    GenServer.call(pid, {"getStepRules"})
  end

  @doc """
  Returns information about symbol available for the user.
  """
  @spec get_symbol(GenServer.server(), XtbClient.Messages.SymbolInfo.Query.t()) ::
          XtbClient.Messages.SymbolInfo.t()
  def get_symbol(pid, %SymbolInfo.Query{} = params) do
    GenServer.call(pid, {"getSymbol", params})
  end

  @doc """
  Returns array of current quotations for given symbols, only quotations that changed from given timestamp are returned.

  New timestamp obtained from output will be used as an argument of the next call of this command.

  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_tick_prices/3` which is the preferred way of retrieving ticks data.**
  """
  @spec get_tick_prices(GenServer.server(), XtbClient.Messages.TickPrices.Query.t()) ::
          XtbClient.Messages.TickPrices.t()
  def get_tick_prices(pid, %TickPrices.Query{} = params) do
    GenServer.call(pid, {"getTickPrices", params})
  end

  @doc """
  Returns array of trades listed in orders query.
  """
  @spec get_trade_records(GenServer.server(), XtbClient.Messages.TradeInfos.Query.t()) ::
          XtbClient.Messages.TradeInfos.t()
  def get_trade_records(pid, %TradeInfos.Query{} = params) do
    GenServer.call(pid, {"getTradeRecords", params})
  end

  @doc """
  Returns array of user's trades.

  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_trades/2` which is the preferred way of retrieving trades data.**
  """
  @spec get_trades(GenServer.server(), XtbClient.Messages.Trades.Query.t()) ::
          XtbClient.Messages.TradeInfos.t()
  def get_trades(pid, %Trades.Query{} = params) do
    GenServer.call(pid, {"getTrades", params})
  end

  @doc """
  Returns array of user's trades which were closed within specified period of time.
  """
  @spec get_trades_history(GenServer.server(), XtbClient.Messages.DateRange.t()) ::
          XtbClient.Messages.TradeInfos.t()
  def get_trades_history(pid, %DateRange{} = params) do
    GenServer.call(pid, {"getTradesHistory", params})
  end

  @doc """
  Returns quotes and trading times.
  """
  @spec get_trading_hours(GenServer.server(), XtbClient.Messages.TradingHours.Query.t()) ::
          XtbClient.Messages.TradingHours.t()
  def get_trading_hours(pid, %TradingHours.Query{} = params) do
    GenServer.call(pid, {"getTradingHours", params})
  end

  @doc """
  Returns the current API version.
  """
  @spec get_version(GenServer.server()) :: XtbClient.Messages.Version.t()
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
  @spec trade_transaction(GenServer.server(), XtbClient.Messages.TradeTransaction.Command.t()) ::
          XtbClient.Messages.TradeTransaction.t()
  def trade_transaction(pid, %TradeTransaction.Command{} = params) do
    GenServer.call(pid, {"tradeTransaction", %{tradeTransInfo: params}})
  end

  @doc """
  Returns current transaction status.

  At any time of transaction processing client might check the status of transaction on server side.
  In order to do that client must provide unique order taken from `trade_transaction/2` invocation.
  """
  @spec trade_transaction_status(
          GenServer.server(),
          XtbClient.Messages.TradeTransactionStatus.Query.t()
        ) ::
          XtbClient.Messages.TradeTransactionStatus.t()
  def trade_transaction_status(pid, %TradeTransactionStatus.Query{} = params) do
    GenServer.call(pid, {"tradeTransactionStatus", params})
  end

  @doc """
  Allows to get actual account indicators values in real-time, as soon as they are available in the system.

  Operation is asynchronous, so the immediate response is an `:ok` atom.
  When the new data are available, the `XtbClient.Messages.BalanceInfo` struct is sent to the `subscriber` process.
  """
  @spec subscribe_get_balance(GenServer.server(), GenServer.server()) :: :ok
  def subscribe_get_balance(pid, subscriber) do
    GenServer.cast(pid, {:subscribe, {subscriber, StreamingMessage.new("getBalance", "balance")}})
  end

  @doc """
  Subscribes for API chart candles.
  The interval of every candle is 1 minute. A new candle arrives every minute.

  Operation is asynchronous, so the immediate response is an `:ok` atom.
  When the new data are available, the `XtbClient.Messages.Candle` struct is sent to the `subscriber` process.
  """
  @spec subscribe_get_candles(
          GenServer.server(),
          GenServer.server(),
          XtbClient.Messages.Candles.Query.t()
        ) :: :ok
  def subscribe_get_candles(pid, subscriber, %Candles.Query{} = params) do
    GenServer.cast(
      pid,
      {:subscribe, {subscriber, StreamingMessage.new("getCandles", "candle", params)}}
    )
  end

  @doc """
  Subscribes for 'keep alive' messages.
  A new 'keep alive' message is sent by the API every 3 seconds.

  Operation is asynchronous, so the immediate response is an `:ok` atom.
  When the new data are available, the `XtbClient.Messages.KeepAlive` struct is sent to the `subscriber` process.
  """
  @spec subscribe_keep_alive(GenServer.server(), GenServer.server()) :: :ok
  def subscribe_keep_alive(pid, subscriber) do
    GenServer.cast(
      pid,
      {:subscribe, {subscriber, StreamingMessage.new("getKeepAlive", "keepAlive")}}
    )
  end

  @doc """
  Subscribes for news.

  Operation is asynchronous, so the immediate response is an `:ok` atom.
  When the new data are available, the `XtbClient.Messages.NewsInfo` struct is sent to the `subscriber` process.
  """
  @spec subscribe_get_news(GenServer.server(), GenServer.server()) :: :ok
  def subscribe_get_news(pid, subscriber) do
    GenServer.cast(pid, {:subscribe, {subscriber, StreamingMessage.new("getNews", "news")}})
  end

  @doc """
  Subscribes for profits.

  Operation is asynchronous, so the immediate response is an `:ok` atom.
  When the new data are available, the `XtbClient.Messages.ProfitInfo` struct is sent to the `subscriber` process.
  """
  @spec subscribe_get_profits(GenServer.server(), GenServer.server()) :: :ok
  def subscribe_get_profits(pid, subscriber) do
    GenServer.cast(pid, {:subscribe, {subscriber, StreamingMessage.new("getProfits", "profit")}})
  end

  @doc """
  Establishes subscription for quotations and allows to obtain the relevant information in real-time, as soon as it is available in the system.
  The `subscribe_get_tick_prices/3` command can be invoked many times for the same symbol, but only one subscription for a given symbol will be created.
  Please beware that when multiple records are available, the order in which they are received is not guaranteed.

  Operation is asynchronous, so the immediate response is an `:ok` atom.
  When the new data are available, the `XtbClient.Messages.TickPrice` struct is sent to the `subscriber` process.
  """
  @spec subscribe_get_tick_prices(
          GenServer.server(),
          GenServer.server(),
          XtbClient.Messages.Quotations.Query.t()
        ) ::
          :ok
  def subscribe_get_tick_prices(pid, subscriber, %Quotations.Query{} = params) do
    GenServer.cast(
      pid,
      {:subscribe, {subscriber, StreamingMessage.new("getTickPrices", "tickPrices", params)}}
    )
  end

  @doc """
  Establishes subscription for user trade status data and allows to obtain the relevant information in real-time, as soon as it is available in the system.
  Please beware that when multiple records are available, the order in which they are received is not guaranteed.

  Operation is asynchronous, so the immediate response is an `:ok` atom.
  When the new data are available, the `XtbClient.Messages.TradeInfo` struct is sent to the `subscriber` process.
  """
  @spec subscribe_get_trades(GenServer.server(), GenServer.server()) :: :ok
  def subscribe_get_trades(pid, subscriber) do
    GenServer.cast(pid, {:subscribe, {subscriber, StreamingMessage.new("getTrades", "trade")}})
  end

  @doc """
  Allows to get status for sent trade requests in real-time, as soon as it is available in the system.
  Please beware that when multiple records are available, the order in which they are received is not guaranteed.

  Operation is asynchronous, so the immediate response is an `:ok` atom.
  When the new data are available, the `XtbClient.Messages.TradeStatus` struct is sent to the `subscriber` process.
  """
  @spec subscribe_get_trade_status(GenServer.server(), GenServer.server()) :: :ok
  def subscribe_get_trade_status(pid, subscriber) do
    GenServer.cast(
      pid,
      {:subscribe, {subscriber, StreamingMessage.new("getTradeStatus", "tradeStatus")}}
    )
  end

  @impl true
  def handle_call({method}, {_pid, ref} = from, %State{mpid: mpid, clients: clients} = state) do
    ref_string = inspect(ref)
    MainSocket.query(mpid, self(), ref_string, method)

    clients = Map.put(clients, ref_string, from)
    state = %State{state | clients: clients}

    {:noreply, state}
  end

  @impl true
  def handle_call(
        {method, params},
        {_pid, ref} = from,
        %State{mpid: mpid, clients: clients} = state
      ) do
    ref_string = inspect(ref)
    MainSocket.query(mpid, self(), ref_string, method, params)

    clients = Map.put(clients, ref_string, from)
    state = %State{state | clients: clients}

    {:noreply, state}
  end

  @impl true
  def handle_cast({:response, ref, resp} = _message, %State{clients: clients} = state) do
    {client, clients} = Map.pop!(clients, ref)
    GenServer.reply(client, resp)
    state = %State{state | clients: clients}

    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:stream_session_id, session_id} = _message,
        %State{type: type, url: url} = state
      ) do
    args = %{
      stream_session_id: session_id,
      type: type,
      url: url
    }

    {:ok, spid} = StreamingSocket.start_link(args)
    state = %{state | spid: spid}

    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:subscribe, {subscriber, %StreamingMessage{} = streaming_message}} = _message,
        %State{spid: spid, subscribers: subscribers} = state
      ) do
    StreamingSocket.subscribe(spid, self(), streaming_message)

    token = StreamingMessage.encode_token(streaming_message)
    subscribers = Map.put(subscribers, token, subscriber)
    state = %State{state | subscribers: subscribers}

    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:stream_result, {token, result}} = _message,
        %State{subscribers: subscribers} = state
      ) do
    subscriber = Map.get(subscribers, token)
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
