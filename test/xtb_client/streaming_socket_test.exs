defmodule XtbClient.StreamingSocketTest do
  use ExUnit.Case
  doctest XtbClient.StreamingSocket

  alias XtbClient.MainSocket
  alias XtbClient.StreamingSocket

  setup_all do
    {:ok, mpid} =
      MainSocket.start_link(%{
        url: System.get_env("XTB_API_URL"),
        user: System.get_env("XTB_API_USERNAME"),
        password: System.get_env("XTB_API_PASSWORD"),
        type: :demo
      })

    Process.sleep(1_000)

    {:ok, %{mpid: mpid}}
  end

  test "subscribes to getBalance", context do
    %{mpid: mpid} = context
    %{url: url, stream_session_id: stream_session_id} = :sys.get_state(mpid)

    stream_params = %{url: "#{url}/demoStream", stream_session_id: stream_session_id}
    {:ok, spid} = StreamingSocket.start_link(stream_params)
    :sys.trace(spid, true)

    :ok = StreamingSocket.subscribe_get_balance(spid)
    Process.sleep(3 * 1000)
  end

  @tag timeout: 2 * 60 * 1000
  test "subscribe to getCandles", context do
    %{mpid: mpid} = context
    %{url: url, stream_session_id: stream_session_id} = :sys.get_state(mpid)

    stream_params = %{url: "#{url}/demoStream", stream_session_id: stream_session_id}
    {:ok, spid} = StreamingSocket.start_link(stream_params)
    :sys.trace(spid, true)

    :ok = StreamingSocket.subscribe_get_candles(spid, "EURPLN")
    Process.sleep(2 * 59 * 1000)
  end

  test "subsribes to getKeepAlive", context do
    %{mpid: mpid} = context
    %{url: url, stream_session_id: stream_session_id} = :sys.get_state(mpid)

    stream_params = %{url: "#{url}/demoStream", stream_session_id: stream_session_id}
    {:ok, spid} = StreamingSocket.start_link(stream_params)
    :sys.trace(spid, true)

    :ok = StreamingSocket.subscribe_keep_alive(spid)
    Process.sleep(6 * 1000)
  end
end
