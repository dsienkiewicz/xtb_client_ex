defmodule XtbClient.MainSocketTest do
  use ExUnit.Case, async: true
  doctest XtbClient.MainSocket

  alias XtbClient.MainSocket

  setup_all do
    {
      :ok,
      %{
        url: System.get_env("XTB_API_URL"),
        user: System.get_env("XTB_API_USERNAME"),
        password: System.get_env("XTB_API_PASSWORD"),
        type: :demo,
        app_name: "XtbClient"
      }
    }
  end

  test "logs in to account", context do
    {:ok, pid} = MainSocket.start_link(context)

    Process.sleep(1_000)

    MainSocket.stream_session_id(pid, self())
    assert_receive {:"$gen_cast", {:stream_session_id, _}}
  end

  @tag timeout: 2 * 30 * 1000
  test "sends ping after login", context do
    {:ok, pid} = MainSocket.start_link(context)

    Process.sleep(2 * 29 * 1000)

    assert Process.alive?(pid) == true
  end
end
