defmodule XtbClient.StreamingSocketMock do
  @moduledoc false

  use XtbClient.StreamingSocket

  @store_mock XtbClient.StreamingTestStoreMock

  @impl XtbClient.StreamingSocket
  def handle_message(_token, message, metadata) do
    alive? = Process.whereis(@store_mock)

    case alive? do
      nil ->
        :ok

      _pid ->
        parent_pid =
          Agent.get(
            @store_mock,
            fn %{parent_pid: pid} -> pid end
          )

        send(parent_pid, {:ok, message, metadata})
        :ok
    end
  end

  @impl XtbClient.StreamingSocket
  def handle_error(error, metadata) do
    alive? = Process.whereis(@store_mock)

    case alive? do
      nil ->
        :ok

      _pid ->
        parent_pid =
          Agent.get(
            @store_mock,
            fn %{parent_pid: pid} -> pid end
          )

        send(parent_pid, {:error, error, metadata})
        :ok
    end
  end
end
