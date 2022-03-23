defmodule XtbClient.StreamingSocketTest do
  use ExUnit.Case, async: true
  doctest XtbClient.StreamingSocket

  alias XtbClient.MainSocket
  alias XtbClient.StreamingSocket

  setup_all do
    type = :demo
    url = System.get_env("XTB_API_URL")

    {:ok, mpid} =
      MainSocket.start_link(%{
        url: url,
        user: System.get_env("XTB_API_USERNAME"),
        password: System.get_env("XTB_API_PASSWORD"),
        type: type,
        app_name: "XtbClient"
      })

    Process.sleep(1_000)
    MainSocket.stream_session_id(mpid, self())

    receive do
      {:"$gen_cast", {:stream_session_id, session_id}} ->
        {:ok, %{url: url, type: type, stream_session_id: session_id}}
    end
  end

  @tag timeout: 2 * 30 * 1000
  test "sends ping after login", context do
    {:ok, pid} = StreamingSocket.start_link(context)

    Process.sleep(2 * 29 * 1000)

    assert Process.alive?(pid) == true
  end
end
