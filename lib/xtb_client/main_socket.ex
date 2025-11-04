defmodule XtbClient.MainSocket do
  @moduledoc """
  WebSocket server used for synchronous communication.

  `MainSocket` is being used like standard `GenServer` - could be started with `start_link/2` and supervised.

  After successful connection to WebSocket the flow is:
  - process casts `login` command to obtain session with backend server,
  - process schedules to itself the `ping` command (with recurring interval) - to maintain persistent connection with backend.
  """
  use WebSockex

  alias XtbClient.AccountType
  alias XtbClient.Error
  alias XtbClient.Messages
  alias XtbClient.RateLimit

  import XtbClient.Messages

  require Logger

  @ping_interval :timer.seconds(30)
  @default_query_timeout :timer.seconds(10)

  defmodule Config do
    @type t :: [
            url: String.t() | URI.t(),
            type: AccountType.t(),
            user: String.t(),
            password: String.t(),
            app_name: String.t()
          ]

    def keys do
      [
        :url,
        :type,
        :user,
        :password,
        :app_name
      ]
    end

    def parse(opts) do
      url = get_in(opts, [:url]) || raise "Missing url in config"
      type = get_in(opts, [:type]) || raise "Missing type in config"

      type = AccountType.format_main(type)

      user = get_in(opts, [:user]) || raise "Missing user in config"
      password = get_in(opts, [:password]) || raise "Missing password in config"
      app_name = get_in(opts, [:app_name]) || raise "Missing app_name in config"

      %{
        url: url |> URI.merge(type) |> URI.to_string(),
        type: type,
        user: user,
        password: password,
        app_name: app_name
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
      :rate_limit
    ]
    defstruct url: nil,
              account_type: nil,
              user: nil,
              password: nil,
              app_name: nil,
              stream_session_id: nil,
              queries: %{},
              rate_limit: nil

    defimpl Inspect do
      def inspect(state, opts) do
        Inspect.Map.inspect(
          %{
            url: state.url,
            account_type: state.account_type,
            user: "<<REDACTED>>",
            password: "<<REDACTED>>",
            app_name: state.app_name,
            stream_session_id: state.stream_session_id,
            queries: state.queries,
            rate_limit: state.rate_limit
          },
          opts
        )
      end
    end
  end

  @doc """
  Starts a `XtbClient.MainSocket` process linked to the calling process.
  """
  @spec start_link(Config.t(), keyword()) :: GenServer.on_start()
  def start_link(args, _opts \\ []) do
    {conn_opts, opts} = Keyword.split(args, Config.keys())

    %{type: type, url: url, user: user, password: password, app_name: app_name} =
      Config.parse(conn_opts)

    state =
      %State{
        url: url,
        account_type: type,
        user: user,
        password: password,
        app_name: app_name,
        queries: %{},
        rate_limit: RateLimit.new(200)
      }

    case WebSockex.start_link(url, __MODULE__, state, opts) do
      {:ok, pid} = result ->
        _ = poll_stream_session_id(pid)

        result

      other ->
        other
    end
  end

  defp poll_stream_session_id(server) do
    case stream_session_id(server) do
      {:ok, nil} ->
        Process.sleep(10)

        poll_stream_session_id(server)

      {:ok, _session_id} = result ->
        result
    end
  end

  @impl WebSockex
  def handle_connect(
        _conn,
        %State{user: user, password: password, app_name: app_name} = state
      ) do
    login_args = %{
      "userId" => user,
      "password" => password,
      "appName" => app_name
    }

    login_message = encode_command("login", login_args)
    WebSockex.cast(self(), {:send, {:text, login_message}})

    ping_command = encode_command("ping")
    ping_message = {:ping, {:text, ping_command}, @ping_interval}
    Process.send_after(self(), ping_message, 1)

    {:ok, state}
  end

  @impl WebSockex
  def handle_disconnect(_connection_status_map, state) do
    Logger.warning("Socket reconnecting")
    {:reconnect, state}
  end

  @doc """
  Calls query to get streaming session ID.

  ## Arguments
  - `server` pid of the main socket process,

  Call to this methods blocks until valid streaming session ID is available - or timeout.
  """
  @spec stream_session_id(GenServer.server()) ::
          {:ok, String.t() | nil} | {:error, :timeout} | {:error, Error.t()}
  def stream_session_id(server) do
    ref_string = inspect(make_ref())

    WebSockex.cast(
      server,
      {:stream_session_id, {self(), ref_string}}
    )

    receive do
      {:"$gen_cast", {:ok, ^ref_string, response}} ->
        {:ok, response}
    after
      @default_query_timeout ->
        {:error, :timeout}
    end
  end

  @doc """
  Handles the API query to the server.
  """
  @spec handle_query(GenServer.server(), Messages.sync_message()) ::
          {:ok, struct()} | {:error, term()}
  def handle_query(server, %struct{} = query) when is_sync_message(struct) do
    ref_string = inspect(make_ref())

    WebSockex.cast(
      server,
      {:query, {self(), ref_string, query}}
    )

    receive do
      {:"$gen_cast", {:ok, ^ref_string, response}} ->
        response = Messages.post_process_response(query, response)
        {:ok, response}

      {:"$gen_cast", {:error, ^ref_string, response}} ->
        {:error, response}
    after
      @default_query_timeout ->
        {:error, :timeout}
    end
  end

  @impl WebSockex
  def handle_cast(
        {:stream_session_id, {caller, ref}},
        %State{stream_session_id: result} = state
      ) do
    GenServer.cast(caller, {:ok, ref, result})

    {:ok, state}
  end

  @impl WebSockex
  def handle_cast(
        {:query, {caller, ref, %message_struct{} = query}},
        %State{queries: queries, rate_limit: rate_limit} = state
      ) do
    rate_limit = RateLimit.check_rate(rate_limit)

    method = Messages.operation(query)
    query_params = Messages.encode(query)
    message = encode_command(method, query_params, ref)
    queries = Map.put(queries, ref, {:query, caller, ref, message_struct})

    state = %State{
      state
      | queries: queries,
        rate_limit: rate_limit
    }

    {:reply, {:text, message}, state}
  end

  @impl WebSockex
  def handle_cast({:send, frame}, state) do
    {:reply, frame, state}
  end

  @impl WebSockex
  def handle_frame({:text, msg}, state) do
    with {:ok, resp} <- Jason.decode(msg),
         {response, caller, state} <- handle_response(resp, state),
         :ok <- GenServer.cast(caller, response) do
      {:ok, state}
    else
      {:ok, _} = result ->
        result

      other ->
        Logger.warning("Socket received unknown message: #{inspect(other)}")
        {:ok, state}
    end
  end

  @impl WebSockex
  def handle_info({:ping, {:text, _command} = frame, interval} = message, state) do
    Process.send_after(self(), message, interval)

    {:reply, frame, state}
  end

  defp encode_command(method, params \\ nil, ref \\ nil) when is_binary(method) do
    %{
      command: method,
      arguments: params,
      customTag: ref
    }
    |> Map.filter(fn {_, value} -> value != nil end)
    |> Jason.encode!()
  end

  defp handle_response(
         %{"status" => true, "returnData" => data, "customTag" => ref},
         %State{queries: queries} = state
       ) do
    {{:query, caller, ^ref, message_struct}, queries} = Map.pop(queries, ref)
    result = Messages.decode(message_struct, data)

    state = %State{state | queries: queries}
    {{:ok, ref, result}, caller, state}
  end

  defp handle_response(%{"status" => true, "streamSessionId" => stream_session_id}, state) do
    state = %State{state | stream_session_id: stream_session_id}
    {:ok, state}
  end

  defp handle_response(%{"status" => true}, state) do
    {:ok, state}
  end

  defp handle_response(
         %{"status" => false, "customTag" => ref} = response,
         %State{queries: queries} = state
       ) do
    {{:query, caller, ^ref, _message_struct}, queries} = Map.pop(queries, ref)

    error = Error.new!(response)
    Logger.error("Socket received error: #{inspect(error)}")

    state = %State{state | queries: queries}
    {{:error, ref, error}, caller, state}
  end
end
