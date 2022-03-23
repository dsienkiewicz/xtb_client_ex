defmodule XtbClient.StreamingSocket do
  use WebSockex

  alias XtbClient.{AccountType}
  alias XtbClient.Messages

  require Logger

  @ping_interval 30 * 1000
  @rate_limit_interval 200

  @moduledoc """
  Documentation for `XtbClient`.
  """

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
    ping_command = encode_streaming_command("ping", stream_session_id)
    ping_message = {:ping, {:text, ping_command}, @ping_interval}
    schedule_work(ping_message, 1)

    {:ok, state}
  end

  defp schedule_work(message, interval) do
    Process.send_after(self(), message, interval)
  end

  def subscribe(client, pid, ref, method) do
    WebSockex.cast(client, {:subscribe, {pid, ref, method}})
  end

  def subscribe(client, pid, ref, method, params) do
    WebSockex.cast(client, {:subscribe, {pid, ref, method, params}})
  end

  @impl WebSockex
  def handle_cast(
        {:subscribe, {pid, ref, method}},
        %{subscriptions: subscriptions, last_sub: last_sub, stream_session_id: session_id} = state
      ) do
    last_sub = check_rate(last_sub, actual_rate())

    message = encode_streaming_command(method, session_id)
    subscriptions = Map.put(subscriptions, ref, {:subscription, pid, ref, method})

    state =
      state
      |> Map.put(:subscriptions, subscriptions)
      |> Map.put(:last_sub, last_sub)

    {:reply, {:text, message}, state}
  end

  @impl WebSockex
  def handle_cast(
        {:subscribe, {pid, ref, method, params}},
        %{subscriptions: subscriptions, last_sub: last_sub, stream_session_id: session_id} = state
      ) do
    last_sub = check_rate(last_sub, actual_rate())

    message = encode_streaming_command(method, session_id, params)
    subscriptions = Map.put(subscriptions, ref, {:subscription, pid, ref, method})

    state =
      state
      |> Map.put(:subscriptions, subscriptions)
      |> Map.put(:last_sub, last_sub)

    {:reply, {:text, message}, state}
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

  defp encode_streaming_command(type, streaming_session_id) do
    Jason.encode!(%{
      command: type,
      streamSessionId: streaming_session_id
    })
  end

  defp encode_streaming_command(type, streaming_session_id, params) do
    %{
      command: type,
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
         %{"command" => command, "data" => data},
         %{subscriptions: subscriptions} = state
       ) do
    {:subscription, pid, ^command, method} = Map.get(subscriptions, command)

    result = Messages.decode_message(method, data)
    GenServer.cast(pid, {:stream, method, result})

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
