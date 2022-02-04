defmodule XtbClient.MainSocket do
  use WebSockex

  alias XtbClient.Messages.{ChartLast, ChartRange, RateInfo}

  require Logger

  @interval 30 * 1000

  @moduledoc """
  Documentation for `XtbClient`.
  """

  def start_link(%{url: url, type: type} = state) do
    account_type = account_type(type)
    url = "#{url}/#{account_type}"

    WebSockex.start_link(url, __MODULE__, state)
  end

  defp account_type(type) do
    case type do
      :demo -> "demo"
      :stream_demo -> "demoStream"
      :real -> "real"
      :real_stream -> "realStream"
    end
  end

  @impl WebSockex
  def handle_connect(_conn, %{user: user, password: password} = state) do
    login_args = %{
      "userId" => user,
      "password" => password,
      "appName" => "XtbClient"
    }

    message = encode_command("login", login_args)
    WebSockex.cast(self(), {:send, {:text, message}})

    ping_command = encode_command("ping")
    ping_message = {:ping, {:text, ping_command}, @interval}
    schedule_work(ping_message, 1)

    {:ok, state}
  end

  defp schedule_work(message, interval) do
    Process.send_after(self(), message, interval)
  end

  def get_all_symbols(client) do
    message = encode_command("getAllSymbols")
    WebSockex.send_frame(client, {:text, message})
  end

  def get_calendar(client) do
    message = encode_command("getCalendar")
    WebSockex.send_frame(client, {:text, message})
  end

  def get_chart_last(client, %ChartLast.Query{} = query) do
    message = %{info: query}
    message = encode_command("getChartLastRequest", message)
    WebSockex.send_frame(client, {:text, message})
  end

  def get_chart_range(client, %ChartRange.Query{} = query) do
    message = %{info: query}
    message = encode_command("getChartRangeRequest", message)
    WebSockex.send_frame(client, {:text, message})
  end

  def get_commission_def(client, symbol, volume) do
    message = encode_command("getCommissionDef", %{"symbol" => symbol, "volume" => volume})
    WebSockex.send_frame(client, {:text, message})
  end

  def get_margin_level(client) do
    message = encode_command("getMarginLevel")
    WebSockex.send_frame(client, {:text, message})
  end

  def get_symbol(client, symbol_name) do
    message = encode_command("getSymbol", %{"symbol" => symbol_name})
    WebSockex.send_frame(client, {:text, message})
  end

  def get_server_time(client) do
    message = encode_command("getServerTime")
    WebSockex.send_frame(client, {:text, message})
  end

  defp encode_command(type, opts) do
    Jason.encode!(%{
      command: type,
      arguments: opts
    })
  end

  defp encode_command(type) do
    Jason.encode!(%{
      command: type
    })
  end

  @impl WebSockex
  def handle_frame({:text, msg}, state) do
    resp = Jason.decode!(msg)

    state = handle_message(resp, state)
    {:ok, state}
  end

  defp handle_message(
         %{"status" => true, "streamSessionId" => stream_session_id} = _message,
         state
       ) do
    Map.put_new(state, :stream_session_id, stream_session_id)
  end

  defp handle_message(
         %{"status" => true, "returnData" => %{"digits" => digits, "rateInfos" => rate_infos}} =
           _message,
         state
       ) do
    rate_infos_response =
      rate_infos
      |> Enum.map(&RateInfo.Result.new(&1, digits))

    IO.inspect("Rate infos: #{inspect(rate_infos_response)}")
    state
  end

  defp handle_message(
         %{
           "status" => true,
           "returnDate" =>
             %{
               commission: _commission,
               rateOfExchange: _rate_of_exchange
             } = response
         } = _message,
         state
       ) do
    IO.inspect("Commission definition: #{inspect(response)}")
    state
  end

  defp handle_message(
         %{"status" => true, "returnData" => _return_data} = message,
         state
       ) do
    IO.inspect("Received response - Type: #:text -- Message: #{inspect(message)}")
    state
  end

  defp handle_message(
         %{"status" => true} = _message,
         state
       ) do
    state
  end

  defp handle_message(%{"status" => false} = message, state) do
    IO.inspect("Handle failed command response - Message: #{inspect(message)}")
    state
  end

  @impl WebSockex
  def handle_cast({:send, frame}, state) do
    {:reply, frame, state}
  end

  @impl WebSockex
  def handle_info({:ping, {:text, _command} = frame, interval} = message, state) do
    schedule_work(message, interval)
    {:reply, frame, state}
  end
end
