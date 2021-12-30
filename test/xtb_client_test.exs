defmodule XtbClientTest do
  use ExUnit.Case
  doctest XtbClient

  setup_all do
    {
      :ok,
      %{
        url: System.get_env("XTB_API_URL"),
        user: System.get_env("XTB_API_USERNAME"),
        password: System.get_env("XTB_API_PASSWORD")
      }
    }
  end

  test "logs in to account", context do
    %{url: url, user: user, password: password} = context

    state = %{url: url}
    {:ok, pid} = XtbClient.start_link(state)

    login_req = %{
      "userId" => user,
      "password" => password,
      "appName" => "XtbClient"
    }

    login_resp = XtbClient.login(pid, login_req)

    Process.sleep(1_000)
    assert :ok = login_resp
  end
end
