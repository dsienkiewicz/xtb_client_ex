defmodule XtbClient.XtbStreamingClient do
  use WebSockex

  require Logger

  @moduledoc """
  Documentation for `XtbClient`.
  """

  def start_link(%{url: url} = state) do
    WebSockex.start_link(url, __MODULE__, state)
  end

  def get_balance(client) do
    %{stream_session_id: stream_session_id} = :sys.get_state(client)
    message = encode_streaming_command("getBalance", stream_session_id)
    WebSockex.send_frame(client, {:text, message})
  end

  defp encode_streaming_command(type, streaming_session_id) do
    Jason.encode!(%{
      command: type,
      streamSessionId: streaming_session_id
    })
  end

  @impl WebSockex
  def handle_frame({:text, msg}, state) do
    resp = Jason.decode!(msg)

    state = handle_message(resp, state)
    {:ok, state}
  end

  defp handle_message(
         %{"command" => "balance", "data" => data} = message,
         state
       ) do
    IO.inspect(
      "Received balance response - Type: #:text -- Message: #{inspect(message)}, data: #{data}"
    )

    state
  end

  defp handle_message(%{"status" => false} = message, state) do
    IO.inspect("Handle failed command response - Message: #{inspect(message)}")
    state
  end
end
