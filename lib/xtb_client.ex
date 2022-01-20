defmodule XtbClient do
  use WebSockex

  require Logger

  @moduledoc """
  Documentation for `XtbClient`.
  """

  def start_link(%{url: url, type: type} = state) do
    account_type = account_type(type)
    url = "#{url}/#{account_type}"

    WebSockex.start_link(url, __MODULE__, state)
  end

  defp account_type(type) do
    case type do
      :demo -> "demo"
      :stream_demo -> "demoStream"
      :real -> "real"
      :real_stream -> "realStream"
    end
  end

  @impl WebSockex
  def handle_connect(_conn, %{user: user, password: password} = state) do
    login_args = %{
      "userId" => user,
      "password" => password,
      "appName" => "XtbClient"
    }

    message = encode_command("login", login_args)
    WebSockex.cast(self(), {:send, {:text, message}})

    {:ok, state}
  end

  def get_all_symbols(client) do
    message = encode_command("getAllSymbols")
    WebSockex.send_frame(client, {:text, message})
  end

  defp encode_command(type, opts) do
    Jason.encode!(%{
      command: type,
      arguments: opts
    })
  end

  defp encode_command(type) do
    Jason.encode!(%{
      command: type
    })
  end

  @impl WebSockex
  def handle_frame({:text, msg}, state) do
    resp = Jason.decode!(msg)

    state = handle_message(resp, state)
    {:ok, state}
  end

  defp handle_message(
         %{"status" => true, "streamSessionId" => stream_session_id} = _message,
         state
       ) do
    Map.put_new(state, :stream_session_id, stream_session_id)
  end

  defp handle_message(
         %{"status" => true, "returnData" => _return_data} = message,
         state
       ) do
    IO.inspect("Received response - Type: #:text -- Message: #{inspect(message)}")
    state
  end

  defp handle_message(%{"status" => false} = message, state) do
    IO.inspect("Handle failed command response - Message: #{inspect(message)}")
    state
  end

  @impl WebSockex
  def handle_cast({:send, frame}, state) do
    {:reply, frame, state}
  end
end
