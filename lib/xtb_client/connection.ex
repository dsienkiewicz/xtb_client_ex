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

    {:ok, state}
  end

  def get_all_symbols(pid) do
    GenServer.call(pid, {"getAllSymbols"})
  end

  def get_calendar(pid) do
    GenServer.call(pid, {"getCalendar"})
  end

  def get_chart_last(pid, %ChartLast.Query{} = params) do
    GenServer.call(pid, {"getChartLastRequest", %{info: params}})
  end

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
        %{subscribers: _subscribers} = state
      ) do
    IO.inspect({method, result}, label: "handle_cast stream")

    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, _reason}, state) do
    {:stop, :shutdown, state}
  end
end
