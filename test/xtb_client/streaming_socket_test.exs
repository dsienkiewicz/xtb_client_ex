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
    stream_session_id = MainSocket.get_stream_session_id(mpid)

    {:ok, %{url: url, type: type, stream_session_id: stream_session_id}}
  end

  test "subscribes to getBalance", context do
    {:ok, spid} = StreamingSocket.start_link(context)
    :sys.trace(spid, true)

    :ok = StreamingSocket.subscribe_get_balance(spid, context)
    Process.sleep(30 * 1000)
  end

  @tag timeout: 2 * 60 * 1000
  test "subscribe to getCandles", context do
    {:ok, spid} = StreamingSocket.start_link(context)
    :sys.trace(spid, true)

    :ok = StreamingSocket.subscribe_get_candles(spid, Map.put(context, :symbol, "EURPLN"))
    Process.sleep(2 * 59 * 1000)
  end

  test "subsribes to getKeepAlive", context do
    {:ok, spid} = StreamingSocket.start_link(context)
    :sys.trace(spid, true)

    :ok = StreamingSocket.subscribe_keep_alive(spid)
    Process.sleep(6 * 1000)
  end

  test "subsribes to getNews", context do
    {:ok, spid} = StreamingSocket.start_link(context)
    :sys.trace(spid, true)

    :ok = StreamingSocket.subscribe_get_news(spid)
    Process.sleep(6 * 1000)
  end

  test "subsribes to getProfit", context do
    {:ok, spid} = StreamingSocket.start_link(context)
    :sys.trace(spid, true)

    :ok = StreamingSocket.subscribe_get_profits(spid)
    Process.sleep(6 * 1000)
  end
end
