defmodule XtbClient.StreamingSocket do
  use WebSockex

  alias XtbClient.{AccountType, StreamingMessage}
  alias XtbClient.Messages

  require Logger

  @ping_interval 30 * 1000
  @rate_limit_interval 200

  @type client :: atom | pid | {atom, any} | {:via, atom, any}

  @moduledoc """
  WebSocket server used for asynchronous communication.
  
  `StreamingSocket` is being used like standard `GenServer` - could be started with `start_link/1` and supervised.
  
  After successful connection to WebSocket the flow is:
  - process schedules to itself the `ping` command (with recurring interval) - to maintain persistent connection with backend.
  """

  @doc """
  Starts a `XtbClient.StreamingSocket` process linked to the calling process.
  """
  @spec start_link(%{
          :stream_session_id => binary(),
          :type => AccountType.t(),
          :url => binary | URI.t(),
          optional(any) => any
        }) :: GenServer.on_start()
  def start_link(%{url: url, type: type, stream_session_id: _stream_session_id} = state) do
    account_type = AccountType.format_streaming(type)
    uri = URI.merge(url, account_type) |> URI.to_string()

    state =
      state
      |> Map.put(:last_sub, actual_rate())
      |> Map.put(:subscriptions, %{})

    WebSockex.start_link(uri, __MODULE__, state)
  end

  @impl WebSockex
  def handle_connect(_conn, %{stream_session_id: stream_session_id} = state) do
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
  @spec subscribe(client(), client(), StreamingMessage.t()) :: :ok
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
          } = _message}},
        %{subscriptions: subscriptions, last_sub: last_sub, stream_session_id: session_id} = state
      ) do
    last_sub = check_rate(last_sub, actual_rate())

    token = StreamingMessage.encode_token(method, params)

    subscriptions =
      Map.update(
        subscriptions,
        response_method,
        {method, %{token => caller}},
        fn {method, value} ->
          {method, Map.put(value, token, caller)}
        end
      )

    state =
      state
      |> Map.put(:subscriptions, subscriptions)
      |> Map.put(:last_sub, last_sub)

    encoded_message = encode_streaming_command({method, params}, session_id)

    {:reply, {:text, encoded_message}, state}
  end

  defp check_rate(prev_rate_ms, actual_rate_ms) do
    rate_diff = actual_rate_ms - prev_rate_ms

    case rate_diff > @rate_limit_interval do
      true ->
        actual_rate_ms

      false ->
        Process.sleep(rate_diff)
        actual_rate()
    end
  end

  defp actual_rate() do
    DateTime.utc_now()
    |> DateTime.to_unix(:millisecond)
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
         %{subscriptions: subscriptions} = state
       ) do
    {method, method_subs} = Map.get(subscriptions, response_method)
    result = Messages.decode_message(method, data)

    token = StreamingMessage.encode_token(method, result)
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
