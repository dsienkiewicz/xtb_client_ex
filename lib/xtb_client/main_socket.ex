defmodule XtbClient.MainSocket do
  @moduledoc """
  WebSocket server used for synchronous communication.

  `MainSocket` is being used like standard `GenServer` - could be started with `start_link/2` and supervised.

  After successful connection to WebSocket the flow is:
  - process casts `login` command to obtain session with backend server,
  - process schedules to itself the `ping` command (with recurring interval) - to maintain persistent connection with backend.
  """
  use WebSockex

  alias XtbClient.AccountType
  alias XtbClient.Error
  alias XtbClient.Messages
  alias XtbClient.RateLimit

  require Logger

  @ping_interval 30 * 1000
  @default_query_timeout 10_000

  defmodule Config do
    @type t :: [
            url: String.t() | URI.t(),
            type: AccountType.t(),
            user: String.t(),
            password: String.t(),
            app_name: String.t()
          ]

    def keys do
      [
        :url,
        :type,
        :user,
        :password,
        :app_name
      ]
    end

    def parse(opts) do
      type = AccountType.format_main(get_in(opts, [:type]))

      %{
        url: get_in(opts, [:url]) |> URI.merge(type) |> URI.to_string(),
        type: type,
        user: get_in(opts, [:user]),
        password: get_in(opts, [:password]),
        app_name: get_in(opts, [:app_name])
      }
    end
  end

  defmodule State do
    @enforce_keys [
      :url,
      :account_type,
      :user,
      :password,
      :app_name,
      :queries,
      :rate_limit
    ]
    defstruct url: nil,
              account_type: nil,
              user: nil,
              password: nil,
              app_name: nil,
              stream_session_id: nil,
              queries: %{},
              rate_limit: nil

    defimpl Inspect do
      def inspect(state, opts) do
        Inspect.Map.inspect(
          %{
            url: state.url,
            account_type: state.account_type,
            user: "<<REDACTED>>",
            password: "<<REDACTED>>",
            app_name: state.app_name,
            stream_session_id: state.stream_session_id,
            queries: state.queries,
            rate_limit: state.rate_limit
          },
          opts
        )
      end
    end
  end

  @doc """
  Starts a `XtbClient.MainSocket` process linked to the calling process.
  """
  @spec start_link(Config.t(), keyword()) :: GenServer.on_start()
  def start_link(args, _opts \\ []) do
    {conn_opts, opts} = Keyword.split(args, Config.keys())

    %{type: type, url: url, user: user, password: password, app_name: app_name} =
      Config.parse(conn_opts)

    state = %State{
      url: url,
      account_type: type,
      user: user,
      password: password,
      app_name: app_name,
      queries: %{},
      rate_limit: RateLimit.new(200)
    }

    case WebSockex.start_link(url, __MODULE__, state, opts) do
      {:ok, pid} = result ->
        _ = poll_stream_session_id(pid)

        result

      other ->
        other
    end
  end

  defp poll_stream_session_id(server) do
    case stream_session_id(server) do
      {:ok, nil} ->
        Process.sleep(10)

        poll_stream_session_id(server)

      {:ok, _session_id} = result ->
        result
    end
  end

  @impl WebSockex
  def handle_connect(
        _conn,
        %State{user: user, password: password, app_name: app_name} = state
      ) do
    login_args = %{
      "userId" => user,
      "password" => password,
      "appName" => app_name
    }

    login_message = encode_command("login", login_args)
    WebSockex.cast(self(), {:send, {:text, login_message}})

    ping_command = encode_command("ping")
    ping_message = {:ping, {:text, ping_command}, @ping_interval}
    schedule_work(ping_message, 1)

    {:ok, state}
  end

  @impl WebSockex
  def handle_disconnect(_connection_status_map, state) do
    Logger.warning("Socket reconnecting")
    {:reconnect, state}
  end

  defp schedule_work(message, interval) do
    Process.send_after(self(), message, interval)
  end

  @doc """
  Calls query to get streaming session ID.

  ## Arguments
  - `server` pid of the main socket process,

  Call to this methods blocks until valid streaming session ID is available - or timeout.
  """
  @spec stream_session_id(GenServer.server()) ::
          {:ok, String.t() | nil} | {:error, :timeout} | {:error, Error.t()}
  def stream_session_id(server) do
    ref_string = inspect(make_ref())

    WebSockex.cast(
      server,
      {:stream_session_id, {self(), ref_string}}
    )

    receive do
      {:"$gen_cast", {:stream_session_id_reply, ^ref_string, response}} ->
        {:ok, response}
    after
      @default_query_timeout ->
        {:error, :timeout}
    end
  end

  @doc """
  Returns array of all symbols available for the user.
  """
  @spec get_all_symbols(GenServer.server()) ::
          {:ok, Messages.SymbolInfos.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_all_symbols(server) do
    handle_query(server, "getAllSymbols")
  end

  @doc """
  Returns calendar with market events.
  """
  @spec get_calendar(GenServer.server()) ::
          {:ok, Messages.CalendarInfos.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_calendar(server) do
    handle_query(server, "getCalendar")
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

  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_candles/2` which is the preferred way of retrieving current candle data.**
  """
  @spec get_chart_last(
          GenServer.server(),
          Messages.ChartLast.Query.t()
        ) :: {:ok, Messages.RateInfos.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_chart_last(server, %Messages.ChartLast.Query{} = params) do
    %Messages.ChartLast.Query{symbol: symbol} = params

    case handle_query(server, "getChartLastRequest", %{info: params}) do
      {:ok, %Messages.RateInfos{data: data} = response} ->
        response = %Messages.RateInfos{
          response
          | data: Enum.map(data, &%Messages.Candle{&1 | symbol: symbol})
        }

        {:ok, response}

      error ->
        error
    end
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

  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_candles/2` which is the preferred way of retrieving current candle data.**
  """
  @spec get_chart_range(GenServer.server(), Messages.ChartRange.Query.t()) ::
          {:ok, Messages.RateInfos.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_chart_range(server, %Messages.ChartRange.Query{} = params) do
    %Messages.ChartRange.Query{symbol: symbol} = params

    case handle_query(server, "getChartRangeRequest", %{info: params}) do
      {:ok, %Messages.RateInfos{data: data} = response} ->
        response = %Messages.RateInfos{
          response
          | data: Enum.map(data, &%Messages.Candle{&1 | symbol: symbol})
        }

        {:ok, response}

      error ->
        error
    end
  end

  @doc """
  Returns calculation of commission and rate of exchange.

  The value is calculated as expected value and therefore might not be perfectly accurate.
  """
  @spec get_commission_def(GenServer.server(), Messages.SymbolVolume.t()) ::
          {:ok, Messages.CommissionDefinition.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_commission_def(server, %Messages.SymbolVolume{} = params) do
    handle_query(server, "getCommissionDef", params)
  end

  @doc """
  Returns information about account currency and account leverage.
  """
  @spec get_current_user_data(GenServer.server()) ::
          {:ok, Messages.UserInfo.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_current_user_data(server) do
    handle_query(server, "getCurrentUserData")
  end

  @doc """
  Returns IBs data from the given time range.
  """
  @spec get_ibs_history(GenServer.server(), Messages.DateRange.t()) ::
          {:ok, map()} | {:error, :timeout} | {:error, Error.t()}
  def get_ibs_history(server, %Messages.DateRange{} = params) do
    handle_query(server, "getIbsHistory", params)
  end

  @doc """
  Returns various account indicators.

  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_balance/1` which is the preferred way of retrieving current account indicators.**
  """
  @spec get_margin_level(GenServer.server()) ::
          {:ok, Messages.BalanceInfo.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_margin_level(server) do
    handle_query(server, "getMarginLevel")
  end

  @doc """
  Returns expected margin for given instrument and volume.

  The value is calculated as expected margin value and therefore might not be perfectly accurate.
  """
  @spec get_margin_trade(GenServer.server(), Messages.SymbolVolume.t()) ::
          {:ok, Messages.MarginTrade.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_margin_trade(server, %Messages.SymbolVolume{} = params) do
    handle_query(server, "getMarginTrade", params)
  end

  @doc """
  Returns news from trading server which were sent within specified period of time.

  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_news/1` which is the preferred way of retrieving news data.**
  """
  @spec get_news(GenServer.server(), Messages.DateRange.t()) ::
          {:ok, Messages.NewsInfos.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_news(server, %Messages.DateRange{} = params) do
    handle_query(server, "getNews", params)
  end

  @doc """
  Calculates estimated profit for given deal data.

  Should be used for calculator-like apps only.
  Profit for opened transactions should be taken from server, due to higher precision of server calculation.
  """
  @spec get_profit_calculation(GenServer.server(), Messages.ProfitCalculation.Query.t()) ::
          {:ok, Messages.ProfitCalculation.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_profit_calculation(server, %Messages.ProfitCalculation.Query{} = params) do
    handle_query(server, "getProfitCalculation", params)
  end

  @doc """
  Returns current time on trading server.
  """
  @spec get_server_time(GenServer.server()) ::
          {:ok, Messages.ServerTime.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_server_time(server) do
    handle_query(server, "getServerTime")
  end

  @doc """
  Returns a list of step rules for DMAs.
  """
  @spec get_step_rules(GenServer.server()) ::
          {:ok, Messages.StepRules.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_step_rules(server) do
    handle_query(server, "getStepRules")
  end

  @doc """
  Returns information about symbol available for the user.
  """
  @spec get_symbol(GenServer.server(), Messages.SymbolInfo.Query.t()) ::
          {:ok, Messages.SymbolInfo.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_symbol(server, %Messages.SymbolInfo.Query{} = params) do
    handle_query(server, "getSymbol", params)
  end

  @doc """
  Returns array of current quotations for given symbols, only quotations that changed from given timestamp are returned.

  New timestamp obtained from output will be used as an argument of the next call of this command.

  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_tick_prices/2` which is the preferred way of retrieving ticks data.**
  """
  @spec get_tick_prices(GenServer.server(), Messages.TickPrices.Query.t()) ::
          {:ok, Messages.TickPrices.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_tick_prices(server, %Messages.TickPrices.Query{} = params) do
    handle_query(server, "getTickPrices", params)
  end

  @doc """
  Returns array of trades listed in orders query.
  """
  @spec get_trade_records(GenServer.server(), Messages.TradeInfos.Query.t()) ::
          {:ok, Messages.TradeInfos.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_trade_records(server, %Messages.TradeInfos.Query{} = params) do
    handle_query(server, "getTradeRecords", params)
  end

  @doc """
  Returns array of user's trades.

  **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_trades/1` which is the preferred way of retrieving trades data.**
  """
  @spec get_trades(GenServer.server(), Messages.Trades.Query.t()) ::
          {:ok, Messages.TradeInfos.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_trades(server, %Messages.Trades.Query{} = params) do
    handle_query(server, "getTrades", params)
  end

  @doc """
  Returns array of user's trades which were closed within specified period of time.
  """
  @spec get_trades_history(GenServer.server(), Messages.DateRange.t()) ::
          {:ok, Messages.TradeInfos.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_trades_history(server, %Messages.DateRange{} = params) do
    handle_query(server, "getTradesHistory", params)
  end

  @doc """
  Returns quotes and trading times.
  """
  @spec get_trading_hours(GenServer.server(), Messages.TradingHours.Query.t()) ::
          {:ok, Messages.TradingHours.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_trading_hours(server, %Messages.TradingHours.Query{} = params) do
    handle_query(server, "getTradingHours", params)
  end

  @doc """
  Returns the current API version.
  """
  @spec get_version(GenServer.server()) ::
          {:ok, Messages.Version.t()} | {:error, :timeout} | {:error, Error.t()}
  def get_version(server) do
    handle_query(server, "getVersion")
  end

  @doc """
  Starts trade transaction.

  `trade_transaction/2` sends main transaction information to the server.

  ## How to verify that the trade request was accepted?
  The status field set to 'true' does not imply that the transaction was accepted. It only means, that the server acquired your request and began to process it.
  To analyse the status of the transaction (for example to verify if it was accepted or rejected) use the `trade_transaction_status/2` command with the order number that came back with the response of the `trade_transaction/2` command.
  """
  @spec trade_transaction(GenServer.server(), Messages.TradeTransaction.Command.t()) ::
          {:ok, Messages.TradeTransaction.t()} | {:error, :timeout} | {:error, Error.t()}
  def trade_transaction(server, %Messages.TradeTransaction.Command{} = params) do
    handle_query(server, "tradeTransaction", %{tradeTransInfo: params})
  end

  @doc """
  Returns current transaction status.

  At any time of transaction processing client might check the status of transaction on server side.
  In order to do that client must provide unique order taken from `trade_transaction/2` invocation.
  """
  @spec trade_transaction_status(
          GenServer.server(),
          Messages.TradeTransactionStatus.Query.t()
        ) ::
          {:ok, Messages.TradeTransactionStatus.t()}
          | {:error, :timeout}
          | {:error, Error.t()}
  def trade_transaction_status(server, %Messages.TradeTransactionStatus.Query{} = params) do
    handle_query(server, "tradeTransactionStatus", params)
  end

  defp handle_query(server, method, params \\ nil) do
    ref_string = inspect(make_ref())

    WebSockex.cast(
      server,
      {:query, {self(), ref_string, {method, params}}}
    )

    receive do
      {:"$gen_cast", {:response, ^ref_string, response}} ->
        {:ok, response}

      {:"$gen_cast", {:error, ^ref_string, response}} ->
        {:error, response}
    after
      @default_query_timeout ->
        {:error, :timeout}
    end
  end

  @impl WebSockex
  def handle_cast(
        {:stream_session_id, {caller, ref}},
        %State{stream_session_id: result} = state
      ) do
    GenServer.cast(caller, {:stream_session_id_reply, ref, result})

    {:ok, state}
  end

  @impl WebSockex
  def handle_cast(
        {:query, {caller, ref, {method, params}}},
        %State{queries: queries, rate_limit: rate_limit} = state
      ) do
    rate_limit = RateLimit.check_rate(rate_limit)

    message = encode_command(method, params, ref)
    queries = Map.put(queries, ref, {:query, caller, ref, method})

    state = %State{
      state
      | queries: queries,
        rate_limit: rate_limit
    }

    {:reply, {:text, message}, state}
  end

  @impl WebSockex
  def handle_cast({:send, frame}, state) do
    {:reply, frame, state}
  end

  defp encode_command(method, params \\ nil, ref \\ nil) when is_binary(method) do
    %{
      command: method,
      arguments: params,
      customTag: ref
    }
    |> Map.filter(fn {_, value} -> value != nil end)
    |> Jason.encode!()
  end

  @impl WebSockex
  def handle_frame({:text, msg}, state) do
    with {:ok, resp} <- Jason.decode(msg),
         {response, caller, state} <- handle_response(resp, state),
         :ok <- GenServer.cast(caller, response) do
      {:ok, state}
    else
      {:ok, _} = result ->
        result

      other ->
        Logger.warning("Socket received unknown message: #{inspect(other)}")
        {:ok, state}
    end
  end

  defp handle_response(
         %{"status" => true, "returnData" => data, "customTag" => ref},
         %State{queries: queries} = state
       ) do
    {{:query, caller, ^ref, method}, queries} = Map.pop(queries, ref)

    result = Messages.decode_message(method, data)

    state = %State{state | queries: queries}
    {{:response, ref, result}, caller, state}
  end

  defp handle_response(%{"status" => true, "streamSessionId" => stream_session_id}, state) do
    state = %State{state | stream_session_id: stream_session_id}
    {:ok, state}
  end

  defp handle_response(%{"status" => true}, state) do
    {:ok, state}
  end

  defp handle_response(
         %{"status" => false, "customTag" => ref} = response,
         %State{queries: queries} = state
       ) do
    {{:query, caller, ^ref, _method}, queries} = Map.pop(queries, ref)

    error = Error.new!(response)
    Logger.error("Socket received error: #{inspect(error)}")

    state = %State{state | queries: queries}
    {{:error, ref, error}, caller, state}
  end

  @impl WebSockex
  def handle_info({:ping, {:text, _command} = frame, interval} = message, state) do
    schedule_work(message, interval)

    {:reply, frame, state}
  end
end
