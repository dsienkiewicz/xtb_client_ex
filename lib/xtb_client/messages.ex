defmodule XtbClient.Messages do
  @moduledoc """
  Module for handling messages from XTB Api.
  """

  alias XtbClient.Messages.{
    BalanceInfo,
    CalendarInfos,
    Candle,
    ChartLast,
    ChartRange,
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
    TickPrices,
    TradeInfos,
    Trades,
    TradeStatus,
    TradeTransaction,
    TradeTransactionStatus,
    TradingHours,
    UserInfo,
    Version
  }

  @sync_messages [
    BalanceInfo.MarginLevelQuery,
    CalendarInfos.Query,
    ChartLast.Query,
    ChartRange.Query,
    CommissionDefinition.Query,
    MarginTrade.Query,
    NewsInfos.Query,
    ProfitCalculation.Query,
    ServerTime.Query,
    StepRules.Query,
    SymbolInfo.Query,
    SymbolInfos.Query,
    TickPrices.Query,
    TradeInfos.Query,
    TradeTransaction.Command,
    TradeTransactionStatus.Query,
    Trades.TradesHistoryQuery,
    Trades.TradesQuery,
    TradingHours.Query,
    UserInfo.Query,
    Version.Query
  ]

  @type sync_message ::
          BalanceInfo.MarginLevelQuery.t()
          | CalendarInfos.Query.t()
          | ChartLast.Query.t()
          | ChartRange.Query.t()
          | CommissionDefinition.Query.t()
          | MarginTrade.Query.t()
          | NewsInfos.Query.t()
          | ProfitCalculation.Query.t()
          | ServerTime.Query.t()
          | StepRules.Query.t()
          | SymbolInfo.Query.t()
          | SymbolInfos.Query.t()
          | TickPrices.Query.t()
          | TradeInfos.Query.t()
          | TradeTransaction.Command.t()
          | TradeTransactionStatus.Query.t()
          | Trades.TradesHistoryQuery.t()
          | Trades.TradesQuery.t()
          | TradingHours.Query.t()
          | UserInfo.Query.t()
          | Version.Query.t()

  @doc "Guards that module is a sync Message, query or command."
  defguard is_sync_message(struct) when struct in @sync_messages

  @doc "Returns the operation key of the Message struct."
  @spec operation(sync_message()) :: String.t()
  def operation(%struct{} = query) when is_sync_message(struct),
    do: struct.operation(query)

  @doc "Encodes the message with `struct` module."
  @spec encode(sync_message()) :: map()
  def encode(%struct{} = data) when is_sync_message(struct),
    do: struct.encode(data)

  @doc "Decodes the message with `struct` module."
  @spec decode(module(), map()) :: struct()
  def decode(struct, data) when is_sync_message(struct) and not is_nil(data),
    do: struct.decode(data)

  @doc "Some messages require post processing, eg. adding `symbol` to `Candle`."
  @spec post_process_response(sync_message(), struct()) :: struct()
  def post_process_response(%struct{} = query, %RateInfos{} = response)
      when struct in [ChartRange.Query, ChartLast.Query] do
    %{symbol: symbol} = query
    %RateInfos{data: data} = response

    %RateInfos{
      response
      | data: Enum.map(data, &%Candle{&1 | symbol: symbol})
    }
  end

  def post_process_response(_query, response), do: response

  def decode_message("getBalance", data), do: BalanceInfo.new(data)

  def decode_message("getCandles", data), do: Candle.new(data)

  def decode_message("getKeepAlive", data), do: KeepAlive.new(data)

  def decode_message("getProfits", data), do: ProfitInfo.new(data)

  def decode_message("getTradeStatus", data), do: TradeStatus.new(data)
end
