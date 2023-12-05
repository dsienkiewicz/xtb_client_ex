defmodule XtbClient.MainSocketTest do
  @moduledoc false
  use ExUnit.Case
  doctest XtbClient.MainSocket

  alias XtbClient.MainSocket

  setup do
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

    {:ok, %{params: params}}
  end

  test "logs in to account", %{params: params} do
    {:ok, pid} = MainSocket.start_link(params)

    Process.sleep(100)

    MainSocket.stream_session_id(pid, self())
    assert_receive {:"$gen_cast", {:stream_session_id, _}}
  end

  @tag timeout: 40 * 1000
  test "sends ping after login", %{params: params} do
    {:ok, pid} = MainSocket.start_link(params)

    Process.sleep(30 * 1000 + 1)

    assert Process.alive?(pid) == true
  end
end
