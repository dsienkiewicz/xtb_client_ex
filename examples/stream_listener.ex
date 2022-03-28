defmodule StreamListener do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_info(message, state) do
    IO.inspect(message, label: "Listener handle info")
    {:noreply, state}
  end
end
