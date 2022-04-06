defmodule XtbClient.MainSocketTest do
  use ExUnit.Case, async: true
  doctest XtbClient.MainSocket

  alias XtbClient.MainSocket

  setup_all do
    Dotenvy.source([
      ".env.#{Mix.env()}",
      ".env.#{Mix.env()}.override",
      System.get_env()
    ])

    url = Dotenvy.env!("XTB_API_URL", :string!)
    user = Dotenvy.env!("XTB_API_USERNAME", :string!)
    passwd = Dotenvy.env!("XTB_API_PASSWORD", :string!)

    params = %{
      url: url,
      user: user,
      password: passwd,
      type: :demo,
      app_name: "XtbClient"
    }

    {:ok, params}
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
