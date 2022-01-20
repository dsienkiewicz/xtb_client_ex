defmodule XtbClientTest do
  use ExUnit.Case
  doctest XtbClient

  setup_all do
    {
      :ok,
      %{
        url: System.get_env("XTB_API_URL"),
        user: System.get_env("XTB_API_USERNAME"),
        password: System.get_env("XTB_API_PASSWORD"),
        type: :demo
      }
    }
  end

  test "logs in to account", context do
    {:ok, pid} = XtbClient.start_link(context)

    Process.sleep(1_000)

    state = :sys.get_state(pid)
    assert state.stream_session_id != nil
  end

  test "get account details", context do
    {:ok, pid} = XtbClient.start_link(context)

    Process.sleep(1_000)

    %{url: url, stream_session_id: stream_session_id} = :sys.get_state(pid)

    stream_params = %{url: "#{url}/demoStream", stream_session_id: stream_session_id}
    {:ok, spid} = XtbClient.XtbStreamingClient.start_link(stream_params)
    :sys.trace(spid, true)

    :ok = XtbClient.XtbStreamingClient.get_balance(spid)
    Process.sleep(5_000)
  end

  test "get all symbols", context do
    {:ok, pid} = XtbClient.start_link(context)

    XtbClient.get_all_symbols(pid)

    Process.sleep(5_000)
  end
end
