defmodule XtbClient.Messages.SymbolInfo do
  defmodule Query do
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

  alias XtbClient.Messages.{MarginMode, ProfitMode, QuoteId}

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
             is_binary(category_name) and is_number(contract_size) and
             is_binary(currency) and is_boolean(currency_pair) and is_binary(currency_profit) and
             is_binary(description) and is_binary(group_name) and
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
             is_binary(symbol) and is_number(tick_size) and is_number(tick_value) and
             is_number(time_value) and is_binary(time_string) and
             is_boolean(trailing_enabled) and is_number(type) do
    %__MODULE__{
      ask: ask,
      bid: bid,
      category_name: category_name,
      contract_size: contract_size,
      currency: currency,
      currency_pair: currency_pair,
      currency_profit: currency_profit,
      description: description,
      expiration: expiration,
      group_name: group_name,
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
      symbol: symbol,
      tick_size: tick_size,
      tick_value: tick_value,
      time: DateTime.from_unix!(time_value, :millisecond),
      time_string: time_string,
      trailing_enabled: trailing_enabled,
      type: type
    }
  end

  def match(%{"ask" => _, "bid" => _, "type" => _} = data) do
    {:ok, __MODULE__.new(data)}
  end

  def match(_data) do
    {:no_match}
  end
end