defmodule XtbClient.MainSocket do
  use WebSockex

  alias XtbClient.{AccountType}

  alias XtbClient.Messages.{
    BalanceInfo,
    CalendarInfo,
    ChartLast,
    ChartRange,
    CommissionDefinition,
    DateRange,
    MarginTrade,
    NewsInfo,
    ProfitCalculation,
    RateInfo,
    SymbolInfo,
    UserInfo
  }

  require Logger

  @interval 30 * 1000

  @moduledoc """
  Documentation for `XtbClient`.
  """

  def start_link(%{url: url, type: type} = state) do
    account_type = AccountType.format_main(type)
    url = "#{url}/#{account_type}"

    state = Map.put(state, :queries, %{})
    WebSockex.start_link(url, __MODULE__, state)
  end

  @impl WebSockex
  def handle_connect(_conn, %{user: user, password: password, app_name: app_name} = state) do
    login_args = %{
      "userId" => user,
      "password" => password,
      "appName" => app_name
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

  def query(client, pid, ref, method, params) do
    WebSockex.cast(client, {:query, {pid, ref, method, params}})
  end

  @impl WebSockex
  def handle_cast({:query, {pid, ref, method, _params}}, %{queries: queries} = state) do
    message = encode_command(method, ref)
    queries = Map.put(queries, ref, {:query, pid, ref})
    state = Map.put(state, :queries, queries)

    {:reply, {:text, message}, state}
  end

  @impl WebSockex
  def handle_cast({:send, frame}, state) do
    {:reply, frame, state}
  end

  def get_stream_session_id(client) do
    %{stream_session_id: stream_session_id} = :sys.get_state(client)
    stream_session_id
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

  def get_current_user_data(client) do
    message = encode_command("getCurrentUserData")
    WebSockex.send_frame(client, {:text, message})
  end

  def get_ibs_history(client, from, to) do
    message = encode_command("getIbsHistory", %{"start" => from, "end" => to})
    WebSockex.send_frame(client, {:text, message})
  end

  def get_margin_level(client) do
    message = encode_command("getMarginLevel")
    WebSockex.send_frame(client, {:text, message})
  end

  def get_margin_trade(client, symbol, volume) do
    message = encode_command("getMarginTrade", %{"symbol" => symbol, "volume" => volume})
    WebSockex.send_frame(client, {:text, message})
  end

  def get_news(client, %DateRange{} = query) do
    message = encode_command("getNews", query)
    WebSockex.send_frame(client, {:text, message})
  end

  def get_profit_calculation(client, %ProfitCalculation.Query{} = query) do
    message = encode_command("getProfitCalculation", query)
    WebSockex.send_frame(client, {:text, message})
  end

  def get_server_time(client) do
    message = encode_command("getServerTime")
    WebSockex.send_frame(client, {:text, message})
  end

  def get_symbol(client, symbol_name) do
    message = encode_command("getSymbol", %{"symbol" => symbol_name})
    WebSockex.send_frame(client, {:text, message})
  end

  defp encode_command(type) do
    Jason.encode!(%{
      command: type
    })
  end

  defp encode_command(type, tag) when is_binary(tag) do
    Jason.encode!(%{
      command: type,
      customTag: tag
    })
  end

  defp encode_command(type, args) when is_map(args) do
    Jason.encode!(%{
      command: type,
      arguments: args
    })
  end

  # defp encode_command(type, args, tag) when is_map(args) and is_binary(tag) do
  #   Jason.encode!(%{
  #     command: type,
  #     arguments: args,
  #     customTag: tag
  #   })
  # end

  @impl WebSockex
  def handle_frame({:text, msg}, %{queries: queries} = state) do
    resp = Jason.decode!(msg)

    case resp do
      %{"customTag" => ref} ->
        {{:query, pid, ^ref}, queries} = Map.pop(queries, ref)
        state = Map.put(state, :queries, queries)

        result = handle_message(resp, state)
        GenServer.cast(pid, {:response, ref, result})

        {:ok, state}

      _ ->
        result = handle_message(resp, state)
        {:ok, result}
    end
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
      |> Enum.map(&RateInfo.new(&1, digits))

    IO.inspect("Rate infos: #{inspect(rate_infos_response)}")
    state
  end

  defp handle_message(
         %{
           "status" => true,
           "returnData" => [%{"ask" => _, "bid" => _} | _] = response
         } = _message,
         _state
       ) do
    symbols_result =
      response
      |> Enum.map(&SymbolInfo.new(&1))

    symbols_result
  end

  defp handle_message(
         %{
           "status" => true,
           "returnData" => [%{"country" => _, "current" => _} | _] = response
         } = _message,
         state
       ) do
    calendar_info =
      response
      |> Enum.map(&CalendarInfo.new(&1))

    IO.inspect("Calendar info: #{inspect(calendar_info)}")
    state
  end

  defp handle_message(
         %{
           "status" => true,
           "returnData" => %{"commission" => _, "rateOfExchange" => _} = response
         } = _message,
         state
       ) do
    commission_def = CommissionDefinition.Result.new(response)
    IO.inspect("Commission definition: #{inspect(commission_def)}")
    state
  end

  defp handle_message(
         %{
           "status" => true,
           "returnData" => %{"companyUnit" => _, "currency" => _} = response
         } = _message,
         state
       ) do
    user_info = UserInfo.new(response)
    IO.inspect("User info: #{inspect(user_info)}")
    state
  end

  defp handle_message(
         %{
           "status" => true,
           "returnData" => %{"balance" => _, "credit" => _} = response
         } = _message,
         state
       ) do
    balance_info = BalanceInfo.new(response)
    IO.inspect("Balance info: #{inspect(balance_info)}")
    state
  end

  defp handle_message(
         %{
           "status" => true,
           "returnData" => %{"margin" => _} = response
         } = _message,
         state
       ) do
    margin_trade = MarginTrade.new(response)
    IO.inspect("Margin trade: #{inspect(margin_trade)}")
    state
  end

  defp handle_message(
         %{
           "status" => true,
           "returnData" => [%{"body" => _, "bodylen" => _} | _] = response
         } = _message,
         state
       ) do
    news_result =
      response
      |> Enum.map(&NewsInfo.new(&1))

    IO.inspect("News result: #{inspect(news_result)}")
    state
  end

  defp handle_message(
         %{
           "status" => true,
           "returnData" => %{"profit" => _} = response
         } = _message,
         state
       ) do
    profit_result = ProfitCalculation.new(response)
    IO.inspect("Profit calculation: #{inspect(profit_result)}")
    state
  end

  defp handle_message(
         %{
           "status" => true,
           "returnData" => %{"ask" => _, "bid" => _} = response
         } = _message,
         state
       ) do
    symbol_info = SymbolInfo.new(response)
    IO.inspect("Symbol info: #{inspect(symbol_info)}")
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
  def handle_info({:ping, {:text, _command} = frame, interval} = message, state) do
    schedule_work(message, interval)
    {:reply, frame, state}
  end
end
