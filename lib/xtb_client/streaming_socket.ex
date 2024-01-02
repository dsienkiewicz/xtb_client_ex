defmodule XtbClient.StreamingSocket do
  @moduledoc """
  WebSocket server used for asynchronous communication.

  `StreamingSocket` is being used like standard `GenServer` - could be started with `start_link/2` and supervised.

  After successful connection to WebSocket the flow is:
  - process schedules to itself the `ping` command (with recurring interval) - to maintain persistent connection with backend
  - process waits for subscription requests from other processes
  - when subscription request is received, process sends subscription command to WebSocket
  - when response from WebSocket is received, process sends result to caller process via `handle_message/2` callback

  The lifecycle of `StreamingSocket` is tightly coupled to `MainSocket` process
  - when `MainSocket` dies, `StreamingSocket` also dies, as `streaming_session_id` is not longer usable.
  Thus, `StreamingSocket` should be supervised in pair with `MainSocket` process.
  """
  use WebSockex

  alias XtbClient.{AccountType, StreamingMessage}
  alias XtbClient.Error
  alias XtbClient.Messages
  alias XtbClient.RateLimit

  require Logger

  @ping_interval 30 * 1000

  defmodule Config do
    @moduledoc false

    @type t :: [
            url: String.t() | URI.t(),
            type: AccountType.t(),
            stream_session_id: String.t(),
            module: module()
          ]

    def keys do
      [
        :url,
        :type,
        :stream_session_id,
        :module
      ]
    end

    def parse(opts) do
      type = AccountType.format_streaming(get_in(opts, [:type]))

      %{
        url: get_in(opts, [:url]) |> URI.merge(type) |> URI.to_string(),
        type: type,
        stream_session_id: get_in(opts, [:stream_session_id]),
        module: get_in(opts, [:module])
      }
    end
  end

  defmodule State do
    @moduledoc false

    @enforce_keys [
      :url,
      :stream_session_id,
      :module,
      :subscriptions,
      :rate_limit
    ]
    defstruct url: nil,
              stream_session_id: nil,
              module: nil,
              subscriptions: %{},
              rate_limit: nil
  end

  @doc """
  Callback invoked when message from WebSocket is received.

  ## Params:
  - `token` - unique token of the subscribed method & params,
  - `message` - struct with response data
  """
  @callback handle_message(
              token :: StreamingMessage.token(),
              message :: struct()
            ) :: :ok

  @doc """
  Callback invoked when error is received from WebSocket.

  ## Params:
  - `error` - struct with error data
  """
  @callback handle_error(error :: Error.t()) :: :ok

  @doc false
  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour XtbClient.StreamingSocket

      @doc false
      def handle_message(token, message) do
        raise "No handle_message/2 clause in #{__MODULE__} provided for #{inspect(message)}"
      end

      @doc false
      def handle_error(error) do
        raise "No handle_error/1 clause in #{__MODULE__} provided for #{inspect(error)}"
      end

      defoverridable handle_message: 2, handle_error: 1
    end
  end

  @doc """
  Starts a `XtbClient.StreamingSocket` process linked to the calling process.
  """
  @spec start_link(Config.t(), keyword()) :: GenServer.on_start()
  def start_link(args, _opts \\ []) do
    {conn_opts, opts} = Keyword.split(args, Config.keys())

    %{url: url, stream_session_id: stream_session_id, module: module} =
      Config.parse(conn_opts)

    state =
      %State{
        url: url,
        stream_session_id: stream_session_id,
        module: module,
        subscriptions: %{},
        rate_limit: RateLimit.new(200)
      }

    WebSockex.start_link(url, __MODULE__, state, opts)
  end

  @impl WebSockex
  def handle_connect(
        _conn,
        %State{stream_session_id: stream_session_id} = state
      ) do
    ping_command = encode_streaming_command({"ping", nil}, stream_session_id)
    ping_message = {:ping, {:text, ping_command}, @ping_interval}
    schedule_work(ping_message, 1)

    {:ok, state}
  end

  defp schedule_work(message, interval) do
    Process.send_after(self(), message, interval)
  end

  @doc """
  Allows to get actual account indicators values in real-time, as soon as they are available in the system.

  Operation is asynchronous, so the immediate response is an `{:ok, token}` tuple, where token is a unique hash of subscribed operation.
  When the new data are available, the `XtbClient.Messages.BalanceInfo` struct is sent via `handle_message/2` callback.
  """
  @spec subscribe_get_balance(socket :: GenServer.server()) ::
          {:ok, StreamingMessage.token()} | {:error, term()}
  def subscribe_get_balance(socket) do
    with message <- StreamingMessage.new("getBalance", "balance"),
         token <- StreamingMessage.encode_token(message),
         :ok <- WebSockex.cast(socket, {:subscribe, message}) do
      {:ok, token}
    else
      err -> {:error, err}
    end
  end

  @doc """
  Subscribes for API chart candles.
  The interval of every candle is 1 minute. A new candle arrives every minute.

  Operation is asynchronous, so the immediate response is an `{:ok, token}` tuple, where token is a unique hash of subscribed operation.
  When the new data are available, the `XtbClient.Messages.Candle` struct is sent via `handle_message/2` callback.
  """
  @spec subscribe_get_candles(
          GenServer.server(),
          XtbClient.Messages.Candles.Query.t()
        ) :: {:ok, StreamingMessage.token()} | {:error, term()}
  def subscribe_get_candles(socket, %Messages.Candles.Query{} = params) do
    with message <- StreamingMessage.new("getCandles", "candle", params),
         token <- StreamingMessage.encode_token(message),
         :ok <- WebSockex.cast(socket, {:subscribe, message}) do
      {:ok, token}
    else
      err -> {:error, err}
    end
  end

  @doc """
  Subscribes for 'keep alive' messages.
  A new 'keep alive' message is sent by the API every 3 seconds.

  Operation is asynchronous, so the immediate response is an `{:ok, token}` tuple, where token is a unique hash of subscribed operation.
  When the new data are available, the `XtbClient.Messages.KeepAlive` struct is sent via `handle_message/2` callback.
  """
  @spec subscribe_keep_alive(GenServer.server()) ::
          {:ok, StreamingMessage.token()} | {:error, term()}
  def subscribe_keep_alive(socket) do
    with message <- StreamingMessage.new("getKeepAlive", "keepAlive"),
         token <- StreamingMessage.encode_token(message),
         :ok <- WebSockex.cast(socket, {:subscribe, message}) do
      {:ok, token}
    else
      err -> {:error, err}
    end
  end

  @doc """
  Subscribes for news.

  Operation is asynchronous, so the immediate response is an `{:ok, token}` tuple, where token is a unique hash of subscribed operation.
  When the new data are available, the `XtbClient.Messages.NewsInfos` struct is sent via `handle_message/2` callback.
  """
  @spec subscribe_get_news(GenServer.server()) ::
          {:ok, StreamingMessage.token()} | {:error, term()}
  def subscribe_get_news(socket) do
    with message <- StreamingMessage.new("getNews", "news"),
         token <- StreamingMessage.encode_token(message),
         :ok <- WebSockex.cast(socket, {:subscribe, message}) do
      {:ok, token}
    else
      err -> {:error, err}
    end
  end

  @doc """
  Subscribes for profits.

  Operation is asynchronous, so the immediate response is an `{:ok, token}` tuple, where token is a unique hash of subscribed operation.
  When the new data are available, the `XtbClient.Messages.ProfitInfo` struct is sent via `handle_message/2` callback.
  """
  @spec subscribe_get_profits(GenServer.server()) ::
          {:ok, StreamingMessage.token()} | {:error, term()}
  def subscribe_get_profits(socket) do
    with message <- StreamingMessage.new("getProfits", "profit"),
         token <- StreamingMessage.encode_token(message),
         :ok <- WebSockex.cast(socket, {:subscribe, message}) do
      {:ok, token}
    else
      err -> {:error, err}
    end
  end

  @doc """
  Establishes subscription for quotations and allows to obtain the relevant information in real-time, as soon as it is available in the system.
  The `subscribe_get_tick_prices/2` command can be invoked many times for the same symbol, but only one subscription for a given symbol will be created.
  Please beware that when multiple records are available, the order in which they are received is not guaranteed.

  Operation is asynchronous, so the immediate response is an `{:ok, token}` tuple, where token is a unique hash of subscribed operation.
  When the new data are available, the `XtbClient.Messages.TickPrice` struct is sent via `handle_message/2` callback.
  """
  @spec subscribe_get_tick_prices(
          GenServer.server(),
          XtbClient.Messages.Quotations.Query.t()
        ) ::
          {:ok, StreamingMessage.token()} | {:error, term()}
  def subscribe_get_tick_prices(socket, %Messages.Quotations.Query{} = params) do
    with message <- StreamingMessage.new("getTickPrices", "tickPrices", params),
         token <- StreamingMessage.encode_token(message),
         :ok <- WebSockex.cast(socket, {:subscribe, message}) do
      {:ok, token}
    else
      err -> {:error, err}
    end
  end

  @doc """
  Establishes subscription for user trade status data and allows to obtain the relevant information in real-time, as soon as it is available in the system.
  Please beware that when multiple records are available, the order in which they are received is not guaranteed.

  Operation is asynchronous, so the immediate response is an `{:ok, token}` tuple, where token is a unique hash of subscribed operation.
  When the new data are available, the `XtbClient.Messages.TradeInfos` struct is sent via `handle_message/2` callback.
  """
  @spec subscribe_get_trades(GenServer.server()) ::
          {:ok, StreamingMessage.token()} | {:error, term()}
  def subscribe_get_trades(socket) do
    with message <- StreamingMessage.new("getTrades", "trade"),
         token <- StreamingMessage.encode_token(message),
         :ok <- WebSockex.cast(socket, {:subscribe, message}) do
      {:ok, token}
    else
      err -> {:error, err}
    end
  end

  @doc """
  Allows to get status for sent trade requests in real-time, as soon as it is available in the system.
  Please beware that when multiple records are available, the order in which they are received is not guaranteed.

  Operation is asynchronous, so the immediate response is an `{:ok, token}` tuple, where token is a unique hash of subscribed operation.
  When the new data are available, the `XtbClient.Messages.TradeStatus` struct is sent via `handle_message/2` callback.
  """
  @spec subscribe_get_trade_status(GenServer.server()) ::
          {:ok, StreamingMessage.token()} | {:error, term()}
  def subscribe_get_trade_status(socket) do
    with message <- StreamingMessage.new("getTradeStatus", "tradeStatus"),
         token <- StreamingMessage.encode_token(message),
         :ok <- WebSockex.cast(socket, {:subscribe, message}) do
      {:ok, token}
    else
      err -> {:error, err}
    end
  end

  @impl WebSockex
  def handle_cast(
        {
          :subscribe,
          %StreamingMessage{
            method: method,
            response_method: response_method,
            params: params
          } = message
        },
        %State{
          subscriptions: subscriptions,
          rate_limit: rate_limit,
          stream_session_id: session_id
        } = state
      ) do
    rate_limit = RateLimit.check_rate(rate_limit)

    subscriptions =
      Map.put(
        subscriptions,
        response_method,
        StreamingMessage.encode_token(message)
      )

    encoded_message = encode_streaming_command({method, params}, session_id)
    state = %{state | subscriptions: subscriptions, rate_limit: rate_limit}

    {:reply, {:text, encoded_message}, state}
  end

  defp encode_streaming_command({method, params}, streaming_session_id)
       when is_binary(method) and is_binary(streaming_session_id) do
    params = if params == nil, do: %{}, else: Map.from_struct(params)

    %{
      command: method,
      streamSessionId: streaming_session_id
    }
    |> Map.merge(params)
    |> Jason.encode!()
  end

  @impl WebSockex
  def handle_frame({:text, msg}, %State{module: module} = state) do
    with {:ok, resp} <- Jason.decode(msg),
         {:ok, {token, message}} <- handle_response(resp, state),
         :ok <- module.handle_message(token, message) do
      {:ok, state}
    else
      {:ok, _} = result ->
        result

      {:error, error} ->
        module.handle_error(error)
        {:ok, state}
    end
  end

  defp handle_response(
         %{"command" => response_method, "data" => data},
         %State{subscriptions: subscriptions} = _state
       ) do
    with token <- Map.get(subscriptions, response_method),
         method <- StreamingMessage.decode_method_name(token),
         result <- Messages.decode_message(method, data) do
      {:ok, {token, result}}
    end
  end

  defp handle_response(%{"status" => true}, state) do
    {:ok, state}
  end

  defp handle_response(
         %{"status" => false} = response,
         _state
       ) do
    error = Error.new!(response)
    Logger.error("Socket received error: #{inspect(error)}")

    {:error, error}
  end

  @impl WebSockex
  def handle_info({:ping, {:text, _command} = frame, interval} = message, state) do
    schedule_work(message, interval)

    {:reply, frame, state}
  end
end
