defmodule StreamListener do
  use GenServer

  def start_link(args) do
    name = Map.get(args, "name") |> String.to_atom()
    GenServer.start_link(__MODULE__, args, name: name)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_info(message, state) do
    IO.inspect({self(), message}, label: "Listener handle info")
    {:noreply, state}
  end
end
