defmodule XtbClient.StreamingSocket do
  use WebSockex

  require Logger

  @interval 30 * 1000

  @moduledoc """
  Documentation for `XtbClient`.
  """

  def start_link(%{url: url} = state) do
    WebSockex.start_link(url, __MODULE__, state)
  end

  @impl WebSockex
  def handle_connect(_conn, %{stream_session_id: stream_session_id} = state) do
    ping_command = encode_streaming_command("ping", stream_session_id)
    ping_message = {:ping, {:text, ping_command}, @interval}
    schedule_work(ping_message, 1)

    {:ok, state}
  end

  defp schedule_work(message, interval) do
    Process.send_after(self(), message, interval)
  end

  def subscribe_get_balance(client) do
    %{stream_session_id: stream_session_id} = :sys.get_state(client)
    message = encode_streaming_command("getBalance", stream_session_id)
    WebSockex.send_frame(client, {:text, message})
  end

  def subscribe_get_candles(client, symbol_name) do
    %{stream_session_id: stream_session_id} = :sys.get_state(client)

    message =
      encode_streaming_command("getCandles", stream_session_id, %{"symbol" => symbol_name})

    WebSockex.send_frame(client, {:text, message})
  end

  def subscribe_get_news(client) do
    %{stream_session_id: stream_session_id} = :sys.get_state(client)
    message = encode_streaming_command("getNews", stream_session_id)
    WebSockex.send_frame(client, {:text, message})
  end

  def subscribe_keep_alive(client) do
    %{stream_session_id: stream_session_id} = :sys.get_state(client)
    message = encode_streaming_command("getKeepAlive", stream_session_id)
    WebSockex.send_frame(client, {:text, message})
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
    |> Map.merge(params)
    |> Jason.encode!()
  end

  @impl WebSockex
  def handle_frame({:text, message}, state) do
    resp = Jason.decode!(message)

    state = handle_message(resp, state)
    {:ok, state}
  end

  defp handle_message(
         %{"command" => "balance", "data" => _data} = _message,
         state
       ) do
    state
  end

  defp handle_message(
         %{"command" => "candle", "data" => _data} = _message,
         state
       ) do
    state
  end

  defp handle_message(
         %{"command" => "keepAlive", "data" => _data} = _message,
         state
       ) do
    state
  end

  defp handle_message(%{"status" => false} = message, state) do
    IO.inspect("Handle failed command response - Message: #{inspect(message)}")
    state
  end

  @impl WebSockex
  def handle_info({:ping, {:text, _command} = frame, interval} = message, state) do
    schedule_work(message, interval)
    {:reply, frame, state}
  end
end
