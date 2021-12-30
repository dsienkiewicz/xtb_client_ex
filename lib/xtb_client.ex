defmodule XtbClient do
  use WebSockex

  require Logger

  @moduledoc """
  Documentation for `XtbClient`.
  """

  def start_link(%{url: url} = state) do
    WebSockex.start_link(url, __MODULE__, state)
  end

  def login(client, opts) do
    message =
      Jason.encode!(%{
        command: "login",
        arguments: opts
      })

    Logger.info("Sending message: #{message}")
    WebSockex.send_frame(client, {:text, message})
  end

  def handle_frame({:text, msg}, state) do
    resp = Jason.decode!(msg)

    state = handle_command_response(resp, state)
    {:ok, state}
  end

  def handle_command_response(
        %{"status" => true, "streamSessionId" => stream_session_id} = message,
        state
      ) do
    IO.inspect("Received login response - Type: #:text -- Message: #{inspect(message)}")
    Map.put_new(state, :stream_session_id, stream_session_id)
  end

  def handle_command_response(%{"status" => false} = message, state) do
    IO.inspect("Handle failed command response - Message: #{inspect(message)}")
    state
  end

  def handle_cast({:send, {type, msg} = frame}, state) do
    IO.inspect("Sending #{type} frame with payload: #{msg}")
    {:reply, frame, state}
  end
end
