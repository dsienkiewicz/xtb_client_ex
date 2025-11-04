defmodule XtbClient.Messages do
  @moduledoc """
  Module for handling messages from XTB Api.
  """

  alias XtbClient.Messages.{
    BalanceInfo,
    CalendarInfos,
    Candle,
    Candles,
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

  @type streaming_message ::
          Candles.SubscribeCandlesCommand.t()
          | TradeStatus.SubscribeTradeStatusCommand.t()
          | TradeStatus.UnsubscribeTradeStatusCommand.t()

  @streaming_messages [
    Candles.SubscribeCandlesCommand,
    TradeStatus.SubscribeTradeStatusCommand,
    TradeStatus.UnsubscribeTradeStatusCommand
  ]

  @doc "Guards that module is a sync Message, query or command."
  defguard is_sync_message(struct) when struct in @sync_messages

  @doc "Guards that module is a streaming Message."
  defguard is_streaming_message(struct) when struct in @streaming_messages

  @doc "Returns the operation key of the Message struct."
  @spec operation(sync_message() | streaming_message()) :: String.t()
  def operation(%struct{} = query)
      when is_sync_message(struct) or is_streaming_message(struct),
      do: struct.operation(query)

  @doc "Encodes the message with `struct` module."
  @spec encode(sync_message() | streaming_message()) :: map()
  def encode(%struct{} = data)
      when is_sync_message(struct) or is_streaming_message(struct),
      do: struct.encode(data)

  @doc "Decodes the message with `struct` module."
  @spec decode(module(), map()) :: struct()
  def decode(struct, data)
      when (is_sync_message(struct) or is_streaming_message(struct)) and not is_nil(data),
      do: struct.decode(data)

  @doc "Calculates a unique hash for the message, which must be the same for related subscribe and unsubscribe messages."
  @spec hash(streaming_message()) :: String.t()
  def hash(%struct{} = data) when is_streaming_message(struct),
    do: struct.hash(data)

  @doc "Returns metadata (provided by client) of a streaming Message."
  @spec fetch_metadata(streaming_message()) :: map() | nil
  def fetch_metadata(%struct{} = data) when is_streaming_message(struct),
    do: struct.fetch_metadata(data)

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
