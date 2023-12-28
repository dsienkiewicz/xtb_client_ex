defmodule XtbClient.StreamingTestStoreMock do
  @moduledoc false
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{parent_pid: nil} end, name: __MODULE__)
  end
end
