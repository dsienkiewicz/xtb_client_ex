defmodule XtbClient.StreamingSocketTest do
  @moduledoc false
  use ExUnit.Case
  doctest XtbClient.StreamingSocket

  alias XtbClient.MainSocket
  alias XtbClient.StreamingSocket

  setup do
    Dotenvy.source([
      ".env.#{Mix.env()}",
      ".env.#{Mix.env()}.override",
      System.get_env()
    ])

    url = Dotenvy.env!("XTB_API_URL", :string!)
    user = Dotenvy.env!("XTB_API_USERNAME", :string!)
    passwd = Dotenvy.env!("XTB_API_PASSWORD", :string!)
    type = :demo

    params = %{
      url: url,
      user: user,
      password: passwd,
      type: :demo,
      app_name: "XtbClient"
    }

    {:ok, mpid} = start_supervised({MainSocket, params})
    Process.sleep(100)
    MainSocket.stream_session_id(mpid, self())

    receive do
      {:"$gen_cast", {:stream_session_id, session_id}} ->
        {:ok, %{params: %{url: url, type: type, stream_session_id: session_id}}}
    end
  end

  @tag timeout: 40 * 1000
  test "sends ping after login", %{params: params} do
    {:ok, pid} = StreamingSocket.start_link(params)

    Process.sleep(30 * 1000 + 1)

    assert Process.alive?(pid) == true
  end
end
