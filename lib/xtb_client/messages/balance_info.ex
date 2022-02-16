defmodule XtbClient.Messages.BalanceInfo do
  @enforce_keys [
    :balance,
    :cash_stock_value,
    :credit,
    :currency,
    :equity,
    :equity_fx,
    :margin,
    :margin_free,
    :margin_level,
    :stock_lock,
    :stock_value
  ]

  @derive Jason.Encoder
  defstruct balance: 0.0,
            cash_stock_value: 0.0,
            credit: 0.0,
            currency: "",
            equity: 0.0,
            equity_fx: 0.0,
            margin: 0.0,
            margin_free: 0.0,
            margin_level: 0.0,
            stock_lock: 0.0,
            stock_value: 0.0

  def new(%{
        "balance" => balance,
        "cashStockValue" => cash_stock_value,
        "credit" => credit,
        "currency" => currency,
        "equity" => equity,
        "equityFX" => equity_fx,
        "margin" => margin,
        "margin_free" => margin_free,
        "margin_level" => margin_level,
        "stockLock" => stock_lock,
        "stockValue" => stock_value
      })
      when is_number(balance) and is_number(cash_stock_value) and is_number(credit) and
             is_binary(currency) and is_number(equity) and is_number(equity_fx) and
             is_number(margin) and is_number(margin_free) and is_number(margin_level) and
             is_number(stock_lock) and is_number(stock_value) do
    %__MODULE__{
      balance: balance,
      cash_stock_value: cash_stock_value,
      credit: credit,
      currency: currency,
      equity: equity,
      equity_fx: equity_fx,
      margin: margin,
      margin_free: margin_free,
      margin_level: margin_level,
      stock_lock: stock_lock,
      stock_value: stock_value
    }
  end

  def new(%{
        "balance" => balance,
        "cashStockValue" => cash_stock_value,
        "credit" => credit,
        "equity" => equity,
        "equityFX" => equity_fx,
        "margin" => margin,
        "marginFree" => margin_free,
        "marginLevel" => margin_level,
        "stockLock" => stock_lock,
        "stockValue" => stock_value
      })
      when is_number(balance) and is_number(cash_stock_value) and is_number(credit) and
             is_number(equity) and is_number(equity_fx) and
             is_number(margin) and is_number(margin_free) and is_number(margin_level) and
             is_number(stock_lock) and is_number(stock_value) do
    %__MODULE__{
      balance: balance,
      cash_stock_value: cash_stock_value,
      credit: credit,
      currency: "",
      equity: equity,
      equity_fx: equity_fx,
      margin: margin,
      margin_free: margin_free,
      margin_level: margin_level,
      stock_lock: stock_lock,
      stock_value: stock_value
    }
  end
end
