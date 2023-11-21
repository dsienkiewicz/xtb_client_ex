defmodule XtbClient.StreamingSocket do
  @moduledoc """
  WebSocket server used for asynchronous communication.

  `StreamingSocket` is being used like standard `GenServer` - could be started with `start_link/1` and supervised.

  After successful connection to WebSocket the flow is:
  - process schedules to itself the `ping` command (with recurring interval) - to maintain persistent connection with backend.
  """
  use WebSockex

  alias XtbClient.{AccountType, StreamingMessage}
  alias XtbClient.Messages
  alias XtbClient.RateLimit

  require Logger

  @ping_interval 30 * 1000

  defmodule Config do
    @type t :: %{
            :url => String.t() | URI.t(),
            :type => AccountType.t(),
            :stream_session_id => String.t()
          }

    def parse(opts) do
      type = AccountType.format_streaming(get_in(opts, [:type]))

      %{
        url: get_in(opts, [:url]) |> URI.merge(type) |> URI.to_string(),
        type: type,
        stream_session_id: get_in(opts, [:stream_session_id])
      }
    end
  end

  defmodule State do
    @enforce_keys [
      :url,
      :stream_session_id,
      :subscriptions,
      :rate_limit
    ]
    defstruct url: nil,
              stream_session_id: nil,
              subscriptions: %{},
              rate_limit: nil
  end

  @doc """
  Starts a `XtbClient.StreamingSocket` process linked to the calling process.
  """
  @spec start_link(Config.t()) :: GenServer.on_start()
  def start_link(opts) do
    %{url: url, stream_session_id: stream_session_id} =
      Config.parse(opts)

    state = %State{
      url: url,
      stream_session_id: stream_session_id,
      subscriptions: %{},
      rate_limit: RateLimit.new(200)
    }

    WebSockex.start_link(url, __MODULE__, state)
  end

  @impl WebSockex
  def handle_connect(_conn, %State{stream_session_id: stream_session_id} = state) do
    ping_command = encode_streaming_command({"ping", nil}, stream_session_id)
    ping_message = {:ping, {:text, ping_command}, @ping_interval}
    schedule_work(ping_message, 1)

    {:ok, state}
  end

  defp schedule_work(message, interval) do
    Process.send_after(self(), message, interval)
  end

  @doc """
  Subscribes `pid` process for messages from `method` query.

  ## Arguments
  - `server` pid of the streaming socket process,
  - `caller` pid of the caller awaiting for the result,
  - `message` struct with call context, see `XtbClient.StreamingMessage`.

  Result of the query will be delivered to message mailbox of the `caller` process.
  """
  @spec subscribe(GenServer.server(), GenServer.server(), StreamingMessage.t()) :: :ok
  def subscribe(
        server,
        caller,
        %StreamingMessage{} = message
      ) do
    WebSockex.cast(server, {:subscribe, {caller, message}})
  end

  @impl WebSockex
  def handle_cast(
        {:subscribe,
         {caller,
          %StreamingMessage{
            method: method,
            response_method: response_method,
            params: params
          } = message}},
        %State{
          subscriptions: subscriptions,
          rate_limit: rate_limit,
          stream_session_id: session_id
        } =
          state
      ) do
    rate_limit = RateLimit.check_rate(rate_limit)

    token = StreamingMessage.encode_token(message)

    subscriptions =
      Map.update(
        subscriptions,
        response_method,
        {method, %{token => caller}},
        fn {method, value} ->
          {method, Map.put(value, token, caller)}
        end
      )

    encoded_message = encode_streaming_command({method, params}, session_id)
    state = %{state | subscriptions: subscriptions, rate_limit: rate_limit}

    {:reply, {:text, encoded_message}, state}
  end

  defp encode_streaming_command({method, nil}, streaming_session_id) do
    Jason.encode!(%{
      command: method,
      streamSessionId: streaming_session_id
    })
  end

  defp encode_streaming_command({method, params}, streaming_session_id) do
    %{
      command: method,
      streamSessionId: streaming_session_id
    }
    |> Map.merge(Map.from_struct(params))
    |> Jason.encode!()
  end

  @impl WebSockex
  def handle_frame({:text, msg}, state) do
    resp = Jason.decode!(msg)
    handle_response(resp, state)
  end

  defp handle_response(
         %{"command" => response_method, "data" => data},
         %State{subscriptions: subscriptions} = state
       ) do
    {method, method_subs} = Map.get(subscriptions, response_method)
    result = Messages.decode_message(method, data)

    token =
      method
      |> StreamingMessage.new(response_method, result)
      |> StreamingMessage.encode_token()

    caller = Map.get(method_subs, token)

    GenServer.cast(caller, {:stream_result, {token, result}})

    {:ok, state}
  end

  defp handle_response(%{"status" => true}, state) do
    {:ok, state}
  end

  defp handle_response(
         %{"status" => false, "errorCode" => code, "errorDescr" => message},
         state
       ) do
    Logger.error("Exception: #{inspect(%{code: code, message: message})}")

    {:close, state}
  end

  @impl WebSockex
  def handle_info({:ping, {:text, _command} = frame, interval} = message, state) do
    schedule_work(message, interval)
    {:reply, frame, state}
  end
end
