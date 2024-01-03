defmodule XtbClient.Messages.SymbolInfo do
  @moduledoc """
  Information relevant to the symbol of security.

  Please be advised that result values for profit and margin calculation can be used optionally, because server is able to perform all profit/margin calculations for Client application by commands described later in this document.

  ## Parameters
  - `ask` ask price in base currency,
  - `bid` bid price in base currency,
  - `category_name` category name,
  - `contract_size` size of 1 lot,
  - `currency` currency,
  - `currency_pair` indicates whether the symbol represents a currency pair,
  - `currency_profit` the currency of calculated profit,
  - `description` description,
  - `expiration` expiration, `null` if not applicable,
  - `group_name` symbol group name,
  - `high` the highest price of the day in base currency,
  - `initial_margin` initial margin for 1 lot order, used for profit/margin calculation,
  - `instant_max_volume` maximum instant volume multiplied by 100 (in lots),
  - `leverage` symbol leverage,
  - `long_only` indicates whether the symbol is long only,
  - `lot_max` maximum size of trade,
  - `lot_min` minimum size of trade,
  - `lot_step` a value of minimum step by which the size of trade can be changed (within `lotMin` - `lotMax` range),
  - `low` the lowest price of the day in base currency,
  - `margin_hedged` used for profit calculation,
  - `margin_hedged_strong` for margin calculation,
  - `margin_maintenance` for margin calculation, `null` if not applicable,
  - `margin_mode` for margin calculation,
  - `percentage` percentage,
  - `pips_precision` number of symbol's pip decimal places,
  - `precision` number of symbol's price decimal places,
  - `profit_mode` for profit calculation,
  - `quote_id` source of price, see `XtbClient.Messages.QuoteId`,
  - `short_selling` indicates whether short selling is allowed on the instrument,
  - `spread_raw` the difference between raw ask and bid prices,
  - `spread_table` spread representation,
  - `starting` `null` if not applicable,
  - `step_rule_id` appropriate step rule ID from `XtbClient.Connection.get_step_rules/1` command response,
  - `stops_level` minimal distance (in pips) from the current price where the stopLoss/takeProfit can be set,
  - `swap_rollover_3_days` time when additional swap is accounted for weekend,
  - `swap_enable` indicates whether swap value is added to position on end of day,
  - `swap_long` swwap value for long positions in pips,
  - `swap_short` swap value for short positions in pips,
  - `swap_type` type of swap calculated,
  - `symbol` symbol name,
  - `tick_size` smallest possible price change, used for profit/margin calculation, `null` if not applicable,
  - `tick_value` value of smallest possible price change (in base currency), used for profit/margin calculation, `null` if not applicable,
  - `time` ask & bid tick time,
  - `time_string` time in string,
  - `trailing_enabled` indicates whether trailing stop (offset) is applicable to the instrument,
  - `type` instrument class number.

  ## Handled Api methods
  - `getSymbol`
  """

  alias XtbClient.Messages.{MarginMode, ProfitMode, QuoteId}

  defmodule Query do
    @moduledoc """
    Info about the query for symbol info.

    ## Parameters
    - `symbol` symbol name.
    """

    @type t :: %__MODULE__{
            symbol: String.t()
          }

    @enforce_keys [:symbol]
    @derive Jason.Encoder
    defstruct symbol: ""

    def new(symbol)
        when is_binary(symbol) do
      %__MODULE__{
        symbol: symbol
      }
    end
  end

  @type t :: %__MODULE__{
          ask: float(),
          bid: float(),
          category_name: String.t(),
          contract_size: integer(),
          currency: String.t(),
          currency_pair: true | false,
          currency_profit: String.t(),
          description: String.t(),
          expiration: DateTime.t() | nil,
          group_name: String.t(),
          high: float(),
          initial_margin: integer(),
          instant_max_volume: integer(),
          leverage: float(),
          long_only: true | false,
          lot_max: float(),
          lot_min: float(),
          lot_step: float(),
          low: float(),
          margin_hedged: integer(),
          margin_hedged_strong: true | false,
          margin_maintenance: integer(),
          margin_mode: MarginMode.t(),
          percentage: float(),
          pips_precision: integer(),
          precision: integer(),
          profit_mode: ProfitMode.t(),
          quote_id: QuoteId.t() | nil,
          short_selling: true | false,
          spread_raw: float(),
          spread_table: float(),
          starting: DateTime.t() | nil,
          step_rule_id: integer(),
          stops_level: integer(),
          swap_rollover_3_days: integer(),
          swap_enable: true | false,
          swap_long: float(),
          swap_short: float(),
          swap_type: integer(),
          symbol: String.t(),
          tick_size: float(),
          tick_value: float(),
          time: DateTime.t(),
          time_string: String.t(),
          trailing_enabled: true | false,
          type: integer()
        }

  @enforce_keys [
    :ask,
    :bid,
    :category_name,
    :contract_size,
    :currency,
    :currency_pair,
    :currency_profit,
    :description,
    :expiration,
    :group_name,
    :high,
    :initial_margin,
    :instant_max_volume,
    :leverage,
    :long_only,
    :lot_max,
    :lot_min,
    :lot_step,
    :low,
    :margin_hedged,
    :margin_hedged_strong,
    :margin_maintenance,
    :margin_mode,
    :percentage,
    :pips_precision,
    :precision,
    :profit_mode,
    :quote_id,
    :short_selling,
    :spread_raw,
    :spread_table,
    :starting,
    :step_rule_id,
    :stops_level,
    :swap_rollover_3_days,
    :swap_enable,
    :swap_long,
    :swap_short,
    :swap_type,
    :symbol,
    :tick_size,
    :tick_value,
    :time,
    :time_string,
    :trailing_enabled,
    :type
  ]
  @derive Jason.Encoder
  defstruct ask: 0.0,
            bid: 0.0,
            category_name: "",
            contract_size: 0,
            currency: "",
            currency_pair: nil,
            currency_profit: "",
            description: "",
            expiration: nil,
            group_name: "",
            high: 0.0,
            initial_margin: 0,
            instant_max_volume: 0,
            leverage: 0.0,
            long_only: nil,
            lot_max: 0.0,
            lot_min: 0.0,
            lot_step: 0.0,
            low: 0.0,
            margin_hedged: 0,
            margin_hedged_strong: nil,
            margin_maintenance: 0,
            margin_mode: nil,
            percentage: 0.0,
            pips_precision: 0,
            precision: 0,
            profit_mode: nil,
            quote_id: nil,
            short_selling: nil,
            spread_raw: 0.0,
            spread_table: 0.0,
            starting: nil,
            step_rule_id: 0,
            stops_level: 0,
            swap_rollover_3_days: 0,
            swap_enable: nil,
            swap_long: 0.0,
            swap_short: 0.0,
            swap_type: 0,
            symbol: "",
            tick_size: 0.0,
            tick_value: 0.0,
            time: nil,
            time_string: "",
            trailing_enabled: nil,
            type: 0

  # credo:disable-for-next-line
  def new(%{
        "ask" => ask,
        "bid" => bid,
        "categoryName" => category_name,
        "contractSize" => contract_size,
        "currency" => currency,
        "currencyPair" => currency_pair,
        "currencyProfit" => currency_profit,
        "description" => description,
        "expiration" => expiration,
        "groupName" => group_name,
        "high" => high,
        "initialMargin" => initial_margin,
        "instantMaxVolume" => instant_max_volume,
        "leverage" => leverage,
        "longOnly" => long_only,
        "lotMax" => lot_max,
        "lotMin" => lot_min,
        "lotStep" => lot_step,
        "low" => low,
        "marginHedged" => margin_hedged,
        "marginHedgedStrong" => margin_hedged_strong,
        "marginMaintenance" => margin_maintenance,
        "marginMode" => margin_mode,
        "percentage" => percentage,
        "pipsPrecision" => pips_precision,
        "precision" => precision,
        "profitMode" => profit_mode,
        "quoteId" => quote_id,
        "shortSelling" => short_selling,
        "spreadRaw" => spread_raw,
        "spreadTable" => spread_table,
        "starting" => starting,
        "stepRuleId" => step_rule_id,
        "stopsLevel" => stops_level,
        "swap_rollover3days" => swap_rollover_3_days,
        "swapEnable" => swap_enabled,
        "swapLong" => swap_long,
        "swapShort" => swap_short,
        "swapType" => swap_type,
        "symbol" => symbol,
        "tickSize" => tick_size,
        "tickValue" => tick_value,
        "time" => time_value,
        "timeString" => time_string,
        "trailingEnabled" => trailing_enabled,
        "type" => type
      })
      when is_number(ask) and is_number(bid) and
             is_number(contract_size) and
             is_boolean(currency_pair) and
             is_number(high) and is_number(initial_margin) and is_number(instant_max_volume) and
             is_number(leverage) and is_boolean(long_only) and
             is_number(lot_max) and is_number(lot_min) and is_number(lot_step) and
             is_number(low) and
             is_number(margin_hedged) and is_boolean(margin_hedged_strong) and
             is_number(margin_maintenance) and is_number(margin_mode) and
             is_number(percentage) and is_number(pips_precision) and is_number(precision) and
             is_number(profit_mode) and is_number(quote_id) and
             is_boolean(short_selling) and is_number(spread_raw) and is_number(spread_table) and
             is_number(step_rule_id) and is_number(stops_level) and
             is_number(swap_rollover_3_days) and
             is_boolean(swap_enabled) and is_number(swap_long) and is_number(swap_short) and
             is_number(swap_type) and
             is_number(tick_size) and is_number(tick_value) and
             is_number(time_value) and
             is_boolean(trailing_enabled) and is_number(type) do
    %__MODULE__{
      ask: ask,
      bid: bid,
      category_name: category_name || "",
      contract_size: contract_size,
      currency: currency || "",
      currency_pair: currency_pair,
      currency_profit: currency_profit || "",
      description: description || "",
      expiration: expiration,
      group_name: group_name || "",
      high: high,
      initial_margin: initial_margin,
      instant_max_volume: instant_max_volume,
      leverage: leverage,
      long_only: long_only,
      lot_max: lot_max,
      lot_min: lot_min,
      lot_step: lot_step,
      low: low,
      margin_hedged: margin_hedged,
      margin_hedged_strong: margin_hedged_strong,
      margin_maintenance: margin_maintenance,
      margin_mode: MarginMode.parse(margin_mode),
      percentage: percentage,
      pips_precision: pips_precision,
      precision: precision,
      profit_mode: ProfitMode.parse(profit_mode),
      quote_id: QuoteId.parse(quote_id),
      short_selling: short_selling,
      spread_raw: spread_raw,
      spread_table: spread_table,
      starting: starting,
      step_rule_id: step_rule_id,
      stops_level: stops_level,
      swap_rollover_3_days: swap_rollover_3_days,
      swap_enable: swap_enabled,
      swap_long: swap_long,
      swap_short: swap_short,
      swap_type: swap_type,
      symbol: symbol || "",
      tick_size: tick_size,
      tick_value: tick_value,
      time: DateTime.from_unix!(time_value, :millisecond),
      time_string: time_string || "",
      trailing_enabled: trailing_enabled,
      type: type
    }
  end
end
