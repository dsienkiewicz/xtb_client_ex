defmodule XtbClient.MainSocket do
  use WebSockex

  alias XtbClient.{AccountType}
  alias XtbClient.Messages

  require Logger

  @ping_interval 30 * 1000
  @rate_limit_interval 200

  @type client :: atom | pid | {atom, any} | {:via, atom, any}

  @moduledoc """
  WebSocket server used for synchronous communication.
  
  `MainSocket` is being used like standard `GenServer` - could be started with `start_link/1` and supervised.
  
  After successful connection to WebSocket the flow is:
  - process casts `login` command to obtain session with backend server,
  - process schedules to itself the `ping` command (with recurring interval) - to maintain persistent connection with backend.
  """

  @doc """
  Starts a `XtbClient.MainSocket` process linked to the calling process.
  """
  @spec start_link(%{
          :app_name => binary(),
          :password => binary(),
          :type => AccountType.t(),
          :url => binary | URI.t(),
          :user => binary(),
          optional(any) => any
        }) :: GenServer.on_start()
  def start_link(
        %{url: url, type: type, user: _user, password: _password, app_name: _app_name} = state
      ) do
    account_type = AccountType.format_main(type)
    uri = URI.merge(url, account_type) |> URI.to_string()

    state =
      state
      |> Map.put(:queries, %{})
      |> Map.put(:last_query, actual_rate())
      |> IO.inspect(label: "main socket state")

    WebSockex.start_link(uri, __MODULE__, state)
  end

  @impl WebSockex
  def handle_connect(_conn, %{user: user, password: password, app_name: app_name} = state) do
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

    state =
      state
      |> Map.delete(:user)
      |> Map.delete(:password)

    {:ok, state}
  end

  defp schedule_work(message, interval) do
    Process.send_after(self(), message, interval)
  end

  @doc """
  Casts query to get streaming session ID.
  
  ## Arguments
  - `client` pid of the main socket process,
  - `pid` pid of the caller awaiting for the result.
  
  Result of the query will be delivered to message mailbox of the `pid` process.
  """
  @spec stream_session_id(client(), client()) :: :ok
  def stream_session_id(client, pid) do
    WebSockex.cast(client, {:stream_session_id, pid})
  end

  @doc """
  Casts query to get data from the backend server.
  
  Might be also used to send command to the backend server.
  
  ## Arguments
  - `client` pid of the main socket process,
  - `pid` pid of the caller awaiting for the result,
  - `ref` unique reference of the query,
  - `method` name of the query method,
  - `params` [optional] arguments of the `method`.
  
  Result of the query will be delivered to message mailbox of the `pid` process.
  """
  @spec query(client(), client(), term(), binary()) :: :ok
  def query(client, pid, ref, method) do
    WebSockex.cast(client, {:query, {pid, ref, method}})
  end

  @spec query(client(), client(), term(), binary(), map()) :: :ok
  def query(client, pid, ref, method, params) do
    WebSockex.cast(client, {:query, {pid, ref, method, params}})
  end

  @impl WebSockex
  def handle_cast(
        {:stream_session_id, pid},
        %{stream_session_id: result} = state
      ) do
    GenServer.cast(pid, {:stream_session_id, result})

    {:ok, state}
  end

  @impl WebSockex
  def handle_cast(
        {:query, {pid, ref, method}},
        %{queries: queries, last_query: last_query} = state
      ) do
    last_query = check_rate(last_query, actual_rate())

    message = encode_command(method, ref)
    queries = Map.put(queries, ref, {:query, pid, ref, method})

    state =
      state
      |> Map.put(:queries, queries)
      |> Map.put(:last_query, last_query)

    {:reply, {:text, message}, state}
  end

  @impl WebSockex
  def handle_cast(
        {:query, {pid, ref, method, params}},
        %{queries: queries, last_query: last_query} = state
      ) do
    last_query = check_rate(last_query, actual_rate())

    message = encode_command(method, params, ref)
    queries = Map.put(queries, ref, {:query, pid, ref, method})

    state =
      state
      |> Map.put(:queries, queries)
      |> Map.put(:last_query, last_query)

    {:reply, {:text, message}, state}
  end

  @impl WebSockex
  def handle_cast({:send, frame}, state) do
    {:reply, frame, state}
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
    {{:query, pid, ^ref, method}, queries} = Map.pop(queries, ref)
    state = Map.put(state, :queries, queries)

    result = Messages.decode_message(method, data)
    GenServer.cast(pid, {:response, ref, result})

    {:ok, state}
  end

  defp handle_response(%{"status" => true, "streamSessionId" => stream_session_id}, state) do
    state = Map.put_new(state, :stream_session_id, stream_session_id)
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
