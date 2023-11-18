defmodule XtbClient.MainSocket do
  @moduledoc """
  WebSocket server used for synchronous communication.

  `MainSocket` is being used like standard `GenServer` - could be started with `start_link/1` and supervised.

  After successful connection to WebSocket the flow is:
  - process casts `login` command to obtain session with backend server,
  - process schedules to itself the `ping` command (with recurring interval) - to maintain persistent connection with backend.
  """
  use WebSockex

  alias XtbClient.{AccountType}
  alias XtbClient.Messages

  require Logger

  @ping_interval 30 * 1000
  @rate_limit_interval 200

  defmodule Config do
    @type t :: %{
            :url => String.t() | URI.t(),
            :type => AccountType.t(),
            :user => String.t(),
            :password => String.t(),
            :app_name => String.t()
          }

    def parse(opts) do
      type = AccountType.format_main(get_in(opts, [:type]))

      %{
        url: get_in(opts, [:url]) |> URI.merge(type) |> URI.to_string(),
        type: type,
        user: get_in(opts, [:user]),
        password: get_in(opts, [:password]),
        app_name: get_in(opts, [:app_name])
      }
    end
  end

  defmodule State do
    @enforce_keys [
      :url,
      :account_type,
      :user,
      :password,
      :app_name,
      :queries,
      :last_query
    ]
    defstruct url: nil,
              account_type: nil,
              user: nil,
              password: nil,
              app_name: nil,
              stream_session_id: nil,
              queries: %{},
              last_query: 0
  end

  @doc """
  Starts a `XtbClient.MainSocket` process linked to the calling process.
  """
  @spec start_link(Config.t()) :: GenServer.on_start()
  def start_link(opts) do
    %{type: type, url: url, user: user, password: password, app_name: app_name} =
      Config.parse(opts)

    state = %State{
      url: url,
      account_type: type,
      user: user,
      password: password,
      app_name: app_name,
      queries: %{},
      last_query: actual_rate()
    }

    WebSockex.start_link(url, __MODULE__, state)
  end

  @impl WebSockex
  def handle_connect(_conn, %State{user: user, password: password, app_name: app_name} = state) do
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

    {:ok, state}
  end

  @impl WebSockex
  def handle_disconnect(_connection_status_map, state) do
    {:reconnect, state}
  end

  defp schedule_work(message, interval) do
    Process.send_after(self(), message, interval)
  end

  @doc """
  Casts query to get streaming session ID.

  ## Arguments
  - `server` pid of the main socket process,
  - `caller` pid of the caller awaiting for the result.

  Result of the query will be delivered to message mailbox of the `caller` process.
  """
  @spec stream_session_id(GenServer.server(), GenServer.server()) :: :ok
  def stream_session_id(server, caller) do
    WebSockex.cast(server, {:stream_session_id, caller})
  end

  @doc """
  Casts query to get data from the backend server.

  Might be also used to send command to the backend server.

  ## Arguments
  - `server` pid of the main socket process,
  - `caller` pid of the caller awaiting for the result,
  - `ref` unique reference of the query,
  - `method` name of the query method,
  - `params` [optional] arguments of the `method`.

  Result of the query will be delivered to message mailbox of the `caller` process.
  """
  @spec query(GenServer.server(), GenServer.server(), term(), String.t()) :: :ok
  def query(server, caller, ref, method) do
    WebSockex.cast(server, {:query, {caller, ref, method}})
  end

  @spec query(GenServer.server(), GenServer.server(), term(), String.t(), map()) :: :ok
  def query(server, caller, ref, method, params) do
    WebSockex.cast(server, {:query, {caller, ref, method, params}})
  end

  @impl WebSockex
  def handle_cast(
        {:stream_session_id, caller},
        %State{stream_session_id: result} = state
      ) do
    GenServer.cast(caller, {:stream_session_id, result})

    {:ok, state}
  end

  @impl WebSockex
  def handle_cast(
        {:query, {caller, ref, method}},
        %State{queries: queries, last_query: last_query} = state
      ) do
    last_query = check_rate(last_query, actual_rate())

    message = encode_command(method, ref)
    queries = Map.put(queries, ref, {:query, caller, ref, method})

    state = %{
      state
      | queries: queries,
        last_query: last_query
    }

    {:reply, {:text, message}, state}
  end

  @impl WebSockex
  def handle_cast(
        {:query, {caller, ref, method, params}},
        %State{queries: queries, last_query: last_query} = state
      ) do
    last_query = check_rate(last_query, actual_rate())

    message = encode_command(method, params, ref)
    queries = Map.put(queries, ref, {:query, caller, ref, method})

    state = %{
      state
      | queries: queries,
        last_query: last_query
    }

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
         %State{queries: queries} = state
       ) do
    {{:query, caller, ^ref, method}, queries} = Map.pop(queries, ref)

    result = Messages.decode_message(method, data)
    GenServer.cast(caller, {:response, ref, result})

    state = %{state | queries: queries}
    {:ok, state}
  end

  defp handle_response(%{"status" => true, "streamSessionId" => stream_session_id}, state) do
    state = %{state | stream_session_id: stream_session_id}
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
