defmodule XtbClient.Connection do
  @moduledoc """
  Module for handling connection to XTB Api.

  `Connection` module is responsible for handling connection to XTB Api.
  It connects to the main socket and streaming socket and provides
  functions for sending and receiving messages.
  """
  use GenServer

  alias XtbClient.MainSocket
  alias XtbClient.MainSocket.Config, as: MainSocketConfig
  alias XtbClient.Messages
  alias XtbClient.StreamingSocket

  import XtbClient.Messages

  defmodule State do
    defstruct mpid: nil,
              spid: nil
  end

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(args) do
    {main_socket_config, opts} = Keyword.split(args, MainSocketConfig.keys())
    {stream_session_config, opts} = Keyword.split(opts, [:module])

    GenServer.start_link(
      __MODULE__,
      %{main: main_socket_config, streaming: stream_session_config},
      opts
    )
  end

  @impl GenServer
  def init(args) do
    with %{main: main_socket_config, streaming: stream_session_config} <- args,
         {:ok, mpid} <- MainSocket.start_link(main_socket_config),
         {:ok, stream_session_id} <- MainSocket.stream_session_id(mpid),
         stream_session_config <-
           Keyword.merge(stream_session_config, stream_session_id: stream_session_id),
         stream_session_config <- Keyword.merge(main_socket_config, stream_session_config),
         {:ok, spid} <-
           StreamingSocket.start_link(stream_session_config) do
      Process.flag(:trap_exit, true)

      state = %State{
        mpid: mpid,
        spid: spid
      }

      {:ok, state}
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  @doc """
  Sends a synchronous message to the main socket.
  """
  @spec sync_call(GenServer.server(), Messages.sync_message()) ::
          {:ok, struct()} | {:error, term()}
  def sync_call(server, %struct{} = query) when is_sync_message(struct) do
    GenServer.call(server, {:sync_call, query})
  end

  @impl true
  def handle_call(
        {:sync_call, query},
        _from,
        %State{mpid: mpid} = state
      ) do
    result = MainSocket.handle_query(mpid, query)
    {:reply, result, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, _reason}, state) do
    {:stop, :shutdown, state}
  end
end
