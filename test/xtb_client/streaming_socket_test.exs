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
        type: type
      })

    Process.sleep(1_000)

    {:ok, %{url: url, type: type, mpid: mpid}}
  end

  @tag timeout: 31 * 1000
  test "subscribes to getBalance", context do
    %{url: url, type: type, mpid: mpid} = context
    %{stream_session_id: stream_session_id} = :sys.get_state(mpid)

    stream_params = %{url: url, type: type, stream_session_id: stream_session_id}
    {:ok, spid} = StreamingSocket.start_link(stream_params)
    :sys.trace(spid, true)

    :ok = StreamingSocket.subscribe_get_balance(spid)
    Process.sleep(30 * 1000)
  end

  @tag timeout: 2 * 60 * 1000
  test "subscribe to getCandles", context do
    %{url: url, type: type, mpid: mpid} = context
    %{stream_session_id: stream_session_id} = :sys.get_state(mpid)

    stream_params = %{url: url, type: type, stream_session_id: stream_session_id}
    {:ok, spid} = StreamingSocket.start_link(stream_params)
    :sys.trace(spid, true)

    :ok = StreamingSocket.subscribe_get_candles(spid, "EURPLN")
    Process.sleep(2 * 59 * 1000)
  end

  test "subsribes to getKeepAlive", context do
    %{url: url, type: type, mpid: mpid} = context
    %{stream_session_id: stream_session_id} = :sys.get_state(mpid)

    stream_params = %{url: url, type: type, stream_session_id: stream_session_id}
    {:ok, spid} = StreamingSocket.start_link(stream_params)
    :sys.trace(spid, true)

    :ok = StreamingSocket.subscribe_keep_alive(spid)
    Process.sleep(6 * 1000)
  end

  test "subsribes to getNews", context do
    %{url: url, type: type, mpid: mpid} = context
    %{stream_session_id: stream_session_id} = :sys.get_state(mpid)

    stream_params = %{url: url, type: type, stream_session_id: stream_session_id}
    {:ok, spid} = StreamingSocket.start_link(stream_params)
    :sys.trace(spid, true)

    :ok = StreamingSocket.subscribe_get_news(spid)
    Process.sleep(6 * 1000)
  end

  test "subsribes to getProfit", context do
    %{url: url, type: type, mpid: mpid} = context
    %{stream_session_id: stream_session_id} = :sys.get_state(mpid)

    stream_params = %{url: url, type: type, stream_session_id: stream_session_id}
    {:ok, spid} = StreamingSocket.start_link(stream_params)
    :sys.trace(spid, true)

    :ok = StreamingSocket.subscribe_get_profits(spid)
    Process.sleep(6 * 1000)
  end
end
