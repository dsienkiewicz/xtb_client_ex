defmodule XtbClient.MainSocket do
  use WebSockex

  alias XtbClient.{AccountType}
  alias XtbClient.Messages

  require Logger

  @interval 30 * 1000

  @moduledoc """
  Documentation for `XtbClient`.
  """

  def start_link(%{url: url, type: type} = state) do
    account_type = AccountType.format_main(type)
    url = "#{url}/#{account_type}"

    state = Map.put(state, :queries, %{})
    WebSockex.start_link(url, __MODULE__, state)
  end

  @impl WebSockex
  def handle_connect(_conn, %{user: user, password: password, app_name: app_name} = state) do
    login_args = %{
      "userId" => user,
      "password" => password,
      "appName" => app_name
    }

    message = encode_command("login", login_args)
    WebSockex.cast(self(), {:send, {:text, message}})

    ping_command = encode_command("ping")
    ping_message = {:ping, {:text, ping_command}, @interval}
    schedule_work(ping_message, 1)

    {:ok, state}
  end

  defp schedule_work(message, interval) do
    Process.send_after(self(), message, interval)
  end

  def query(client, pid, ref, method) do
    WebSockex.cast(client, {:query, {pid, ref, method}})
  end

  def query(client, pid, ref, method, params) do
    WebSockex.cast(client, {:query, {pid, ref, method, params}})
  end

  @impl WebSockex
  def handle_cast({:query, {pid, ref, method}}, %{queries: queries} = state) do
    message = encode_command(method, ref)
    queries = Map.put(queries, ref, {:query, pid, ref})
    state = Map.put(state, :queries, queries)

    {:reply, {:text, message}, state}
  end

  @impl WebSockex
  def handle_cast({:query, {pid, ref, method, params}}, %{queries: queries} = state) do
    message = encode_command(method, params, ref)
    queries = Map.put(queries, ref, {:query, pid, ref})
    state = Map.put(state, :queries, queries)

    {:reply, {:text, message}, state}
  end

  @impl WebSockex
  def handle_cast({:send, frame}, state) do
    {:reply, frame, state}
  end

  def get_stream_session_id(client) do
    %{stream_session_id: stream_session_id} = :sys.get_state(client)
    stream_session_id
  end

  defp encode_command(type) do
    Jason.encode!(%{
      command: type
    })
  end

  defp encode_command(type, tag) when is_binary(tag) do
    Jason.encode!(%{
      command: type,
      customTag: tag
    })
  end

  defp encode_command(type, args) when is_map(args) do
    Jason.encode!(%{
      command: type,
      arguments: args
    })
  end

  defp encode_command(type, args, tag) when is_map(args) and is_binary(tag) do
    Jason.encode!(%{
      command: type,
      arguments: args,
      customTag: tag
    })
  end

  @impl WebSockex
  def handle_frame({:text, msg}, state) do
    resp = Jason.decode!(msg)
    handle_response(resp, state)
  end

  defp handle_response(
         %{"status" => true, "returnData" => data, "customTag" => ref},
         %{queries: queries} = state
       ) do
    {{:query, pid, ^ref}, queries} = Map.pop(queries, ref)
    state = Map.put(state, :queries, queries)

    result = Messages.decode_message(data)
    GenServer.cast(pid, {:response, ref, result})

    {:ok, state}
  end

  defp handle_response(%{"status" => true, "streamSessionId" => stream_session_id}, state) do
    state = Map.put_new(state, :stream_session_id, stream_session_id)
    # GenServer.cast(pid, {:response, ref, result})

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
