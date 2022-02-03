defmodule XtbClient.MainSocketTest do
  use ExUnit.Case, async: true
  doctest XtbClient.MainSocket

  alias XtbClient.MainSocket
  alias XtbClient.Messages.{ChartLast}

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
    {:ok, pid} = MainSocket.start_link(context)

    Process.sleep(1_000)

    state = :sys.get_state(pid)
    assert state.stream_session_id != nil
  end

  @tag timeout: 2 * 60 * 1000
  test "sends ping after login", context do
    {:ok, pid} = MainSocket.start_link(context)
    :sys.trace(pid, true)

    Process.sleep(2 * 59 * 1000)
  end

  test "get all symbols", context do
    {:ok, pid} = MainSocket.start_link(context)

    MainSocket.get_all_symbols(pid)

    Process.sleep(5_000)
  end

  test "get calendar", context do
    {:ok, pid} = MainSocket.start_link(context)

    MainSocket.get_calendar(pid)

    Process.sleep(5_000)
  end

  test "get chart last", context do
    {:ok, pid} = MainSocket.start_link(context)
    :sys.trace(pid, true)

    args = %{
      period: :h1,
      start: DateTime.utc_now() |> DateTime.add(-30 * 24 * 60 * 60),
      symbol: "EURPLN"
    }

    query = ChartLast.Query.new(args)

    MainSocket.get_chart_last(pid, query)

    Process.sleep(5_000)
  end

  test "get margin level", context do
    {:ok, pid} = MainSocket.start_link(context)

    MainSocket.get_margin_level(pid)

    Process.sleep(5_000)
  end

  test "get symbol", context do
    {:ok, pid} = MainSocket.start_link(context)

    MainSocket.get_symbol(pid, "EURPLN")

    Process.sleep(5_000)
  end

  test "get server time", context do
    {:ok, pid} = MainSocket.start_link(context)

    MainSocket.get_server_time(pid)

    Process.sleep(5_000)
  end
end
