defmodule XtbClient.Connection do
  use GenServer

  alias XtbClient.{MainSocket, StreamingSocket}

  def start_link(args) do
    state = Map.put(args, :clients, %{})
    GenServer.start_link(__MODULE__, state, [])
  end

  @impl true
  def init(state) do
    {:ok, mpid} = MainSocket.start_link(state)
    Process.sleep(1_000)

    session_id = MainSocket.get_stream_session_id(mpid)
    args = Map.put(state, :stream_session_id, session_id)
    {:ok, spid} = StreamingSocket.start_link(args)

    Process.flag(:trap_exit, true)

    new_state =
      state
      |> Map.put(:mpid, mpid)
      |> Map.put(:spid, spid)

    {:ok, new_state}
  end

  def get_all_symbols(pid) do
    GenServer.call(pid, {:get_all_symbols})
  end

  @impl true
  def handle_call({:get_all_symbols}, {_pid, ref} = from, %{mpid: mpid, clients: clients} = state) do
    ref_string = inspect(ref)
    MainSocket.query(mpid, self(), ref_string, "getAllSymbols", nil)

    clients = Map.put(clients, ref_string, from)
    state = %{state | clients: clients}

    {:noreply, state}
  end

  @impl true
  def handle_cast({:response, ref, resp} = _message, %{clients: clients} = state) do
    {client, clients} = Map.pop!(clients, ref)
    GenServer.reply(client, resp)
    state = %{state | clients: clients}

    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, _reason}, state) do
    {:stop, :shutdown, state}
  end
end
