defmodule XtbClient.Messages do
  @moduledoc """
  Module for handling messages from XTB Api.
  """

  alias XtbClient.Messages.{
    BalanceInfo,
    CalendarInfos,
    Candle,
    CommissionDefinition,
    KeepAlive,
    MarginTrade,
    NewsInfos,
    ProfitCalculation,
    ProfitInfo,
    RateInfos,
    ServerTime,
    StepRules,
    SymbolInfo,
    SymbolInfos,
    TickPrice,
    TickPrices,
    TradeInfos,
    TradeStatus,
    TradeTransaction,
    TradeTransactionStatus,
    TradingHours,
    UserInfo,
    Version
  }

  def decode_message("getBalance", data), do: BalanceInfo.new(data)
  def decode_message("getMarginLevel", data), do: BalanceInfo.new(data)

  def decode_message("getCalendar", data), do: CalendarInfos.new(data)

  def decode_message("getCandles", data), do: Candle.new(data)

  def decode_message("getCommissionDef", data), do: CommissionDefinition.new(data)

  def decode_message("getKeepAlive", data), do: KeepAlive.new(data)

  def decode_message("getMarginTrade", data), do: MarginTrade.new(data)

  def decode_message("getNews", data), do: NewsInfos.new(data)

  def decode_message("getProfitCalculation", data), do: ProfitCalculation.new(data)

  def decode_message("getProfits", data), do: ProfitInfo.new(data)

  def decode_message("getChartLastRequest", data), do: RateInfos.new(data)
  def decode_message("getChartRangeRequest", data), do: RateInfos.new(data)

  def decode_message("getServerTime", data), do: ServerTime.new(data)

  def decode_message("getStepRules", data), do: StepRules.new(data)

  def decode_message("getSymbol", data), do: SymbolInfo.new(data)

  def decode_message("getAllSymbols", data), do: SymbolInfos.new(data)

  def decode_message("getTickPrices", %{"quotations" => data}) when is_list(data),
    do: TickPrices.new(data)

  def decode_message("getTickPrices", data) when is_map(data) and map_size(data) > 1,
    do: TickPrice.new(data)

  def decode_message("getTradeRecords", data), do: TradeInfos.new(data)
  def decode_message("getTrades", data), do: TradeInfos.new(data)
  def decode_message("getTradesHistory", data), do: TradeInfos.new(data)

  def decode_message("getTradeStatus", data), do: TradeStatus.new(data)

  def decode_message("tradeTransactionStatus", data), do: TradeTransactionStatus.new(data)

  def decode_message("tradeTransaction", data), do: TradeTransaction.new(data)

  def decode_message("getTradingHours", data), do: TradingHours.new(data)

  def decode_message("getCurrentUserData", data), do: UserInfo.new(data)

  def decode_message("getVersion", data), do: Version.new(data)
end
