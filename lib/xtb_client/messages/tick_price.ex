defmodule XtbClient.Messages.TickPrice do
  alias XtbClient.Messages.QuoteId

  @moduledoc """
  Info about one tick price.
  
  Parameters:
  - `ask` ask price in base currency,
  - `ask_volume` number of available lots to buy at given price or `null` if not applicable
  - `bid` bid price in base currency,
  - `bid_volume` number of available lots to buy at given price or `null` if not applicable,
  - `exe_mode` exe mode,
  - `high` the highest price of the day in base currency,
  - `level` price level,
  - `low` the lowest price of the day in base currency,
  - `quote_id` quote ID or `null` if not applicable,
  - `spread_raw` the difference between raw ask and bid prices,
  - `spread_table` spread representation,
  - `symbol` symbol,
  - `timestamp` timestamp.
  """

  @type t :: %__MODULE__{
          ask: float(),
          ask_volume: integer() | nil,
          bid: float(),
          bid_volume: integer() | nil,
          exe_mode: any(),
          high: float(),
          level: integer(),
          low: float(),
          quote_id: integer() | nil,
          spread_raw: float(),
          spread_table: float(),
          symbol: binary(),
          timestamp: DateTime.t()
        }

  @enforce_keys [
    :ask,
    :ask_volume,
    :bid,
    :bid_volume,
    :high,
    :level,
    :low,
    :spread_raw,
    :spread_table,
    :symbol,
    :timestamp
  ]

  defstruct ask: 0.0,
            ask_volume: nil,
            bid: 0.0,
            bid_volume: nil,
            exe_mode: nil,
            high: 0.0,
            level: nil,
            low: 0.0,
            quote_id: nil,
            spread_raw: 0.0,
            spread_table: 0.0,
            symbol: "",
            timestamp: nil

  def new(
        %{
          "exemode" => exemode
        } = args
      )
      when is_integer(exemode) do
    value = __MODULE__.new(Map.delete(args, "exemode"))
    %{value | exe_mode: exemode}
  end

  def new(
        %{
          "quoteId" => quote_id
        } = args
      )
      when is_integer(quote_id) do
    value = __MODULE__.new(Map.delete(args, "quoteId"))
    %{value | quote_id: QuoteId.parse(quote_id)}
  end

  def new(%{
        "ask" => ask,
        "askVolume" => ask_volume,
        "bid" => bid,
        "bidVolume" => bid_volume,
        "high" => high,
        "level" => level,
        "low" => low,
        "spreadRaw" => spread_raw,
        "spreadTable" => spread_table,
        "symbol" => symbol,
        "timestamp" => timestamp_value
      })
      when is_number(ask) and
             is_number(bid) and
             is_number(high) and
             is_integer(level) and
             is_number(low) and
             is_number(spread_raw) and is_number(spread_table) and
             is_binary(symbol) and
             is_integer(timestamp_value) do
    %__MODULE__{
      ask: ask,
      ask_volume: ask_volume,
      bid: bid,
      bid_volume: bid_volume,
      high: high,
      level: level,
      low: low,
      spread_raw: spread_raw,
      spread_table: spread_table,
      symbol: symbol,
      timestamp: DateTime.from_unix!(timestamp_value, :millisecond)
    }
  end
end
