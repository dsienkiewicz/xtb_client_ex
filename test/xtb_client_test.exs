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

  describe "sync API" do
    test "logs in to account", context do
      {:ok, pid} = XtbClient.start_link(context)

      Process.sleep(1_000)

      state = :sys.get_state(pid)
      assert state.stream_session_id != nil
    end

    @tag timeout: 2 * 60 * 1000
    test "sends ping after login", context do
      {:ok, pid} = XtbClient.start_link(context)
      :sys.trace(pid, true)

      Process.sleep(2 * 59 * 1000)
    end

    test "get all symbols", context do
      {:ok, pid} = XtbClient.start_link(context)

      XtbClient.get_all_symbols(pid)

      Process.sleep(5_000)
    end

    test "get margin level", context do
      {:ok, pid} = XtbClient.start_link(context)

      XtbClient.get_margin_level(pid)

      Process.sleep(5_000)
    end

    test "get symbol", context do
      {:ok, pid} = XtbClient.start_link(context)

      XtbClient.get_symbol(pid, "EURPLN")

      Process.sleep(5_000)
    end
  end

  describe "subcription API" do
    test "subscribes to getBalance", context do
      {:ok, pid} = XtbClient.start_link(context)
      Process.sleep(1_000)

      %{url: url, stream_session_id: stream_session_id} = :sys.get_state(pid)

      stream_params = %{url: "#{url}/demoStream", stream_session_id: stream_session_id}
      {:ok, spid} = XtbClient.XtbStreamingClient.start_link(stream_params)
      :sys.trace(spid, true)

      :ok = XtbClient.XtbStreamingClient.subscribe_get_balance(spid)
      Process.sleep(50_000)
    end

    @tag timeout: 10 * 60 * 1000
    test "subscribe to getCandles", context do
      {:ok, pid} = XtbClient.start_link(context)
      :sys.trace(pid, true)
      Process.sleep(1_000)

      %{url: url, stream_session_id: stream_session_id} = :sys.get_state(pid)

      stream_params = %{url: "#{url}/demoStream", stream_session_id: stream_session_id}
      {:ok, spid} = XtbClient.XtbStreamingClient.start_link(stream_params)
      :sys.trace(spid, true)

      :ok = XtbClient.XtbStreamingClient.subscribe_get_candles(spid, "EURPLN")
      Process.sleep(10 * 59 * 1000)
    end

    test "subsribes to getKeepAlive", context do
      {:ok, pid} = XtbClient.start_link(context)
      Process.sleep(1_000)

      %{url: url, stream_session_id: stream_session_id} = :sys.get_state(pid)

      stream_params = %{url: "#{url}/demoStream", stream_session_id: stream_session_id}
      {:ok, spid} = XtbClient.XtbStreamingClient.start_link(stream_params)
      :sys.trace(spid, true)

      :ok = XtbClient.XtbStreamingClient.subscribe_keep_alive(spid)
      Process.sleep(50_000)
    end
  end
end
