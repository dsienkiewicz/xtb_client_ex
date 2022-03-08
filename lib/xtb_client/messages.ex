defmodule XtbClient.Messages do
  alias XtbClient.Messages.{
    BalanceInfo,
    CalendarInfos,
    CommissionDefinition,
    MarginTrade,
    NewsInfos,
    Period,
    ProfitCalculation,
    RateInfos,
    ServerTime,
    StepRules,
    SymbolInfo,
    SymbolInfos,
    TickPrices,
    TradeInfos,
    TradeTransaction,
    TradeTransactionStatus,
    TradingHours,
    UserInfo,
    Version
  }

  def format_period(period) do
    Period.format(period)
  end

  def parse_period(value) do
    Period.parse(value)
  end

  @message_handlers [
    BalanceInfo,
    CalendarInfos,
    CommissionDefinition,
    MarginTrade,
    NewsInfos,
    ProfitCalculation,
    RateInfos,
    ServerTime,
    StepRules,
    SymbolInfo,
    SymbolInfos,
    TickPrices,
    TradeInfos,
    TradeTransaction,
    TradeTransactionStatus,
    TradingHours,
    UserInfo,
    Version
  ]

  def decode_message(data) do
    result =
      @message_handlers
      |> Enum.map(& &1.match(data))
      # |> Enum.map(fn h ->
      #   try do
      #     IO.inspect(h, label: "map handler")
      #     IO.inspect(data, label: "return response data")
      #     h.match(data)
      #   rescue
      #     x -> IO.inspect(x, label: "rescue")
      #   end
      # end)
      |> Enum.find(fn x ->
        case x do
          {:ok, _} = res -> res
          {:no_match} -> false
        end
      end)

    case result do
      {:ok, mapped_result} -> mapped_result
      _ -> {:error, "No handler found for data #{inspect(data)}."}
    end
  end
end
