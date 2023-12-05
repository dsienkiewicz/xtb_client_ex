defmodule XtbClient.Messages.BalanceInfo do
  @moduledoc """
  Info about current account indicators.

  ## Parameters
  - `balance` balance in account currency,
  - `cash_stock_value` value of stock in cash,
  - `credit` credit,
  - `currency` user currency,
  - `equity` sum of balance and all profits in account currency,
  - `equity_fx` equity FX,
  - `margin` margin requirements in account currency,
  - `margin_free` free margin in account currency,
  - `margin_level` margin level percentage,
  - `stock_lock` stock lock,
  - `stock_value` stock value.

  ## Handled Api methods
  - `getBalance`
  - `getMarginLevel`
  """

  @type t :: %__MODULE__{
          balance: float(),
          cash_stock_value: float(),
          credit: float(),
          currency: String.t() | nil,
          equity: float(),
          equity_fx: float(),
          margin: float(),
          margin_free: float(),
          margin_level: float(),
          stock_lock: float(),
          stock_value: float()
        }

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
            currency: nil,
            equity: 0.0,
            equity_fx: 0.0,
            margin: 0.0,
            margin_free: 0.0,
            margin_level: 0.0,
            stock_lock: 0.0,
            stock_value: 0.0

  def new(%{"currency" => currency} = args) do
    value = args |> Map.drop(["currency"]) |> new()

    %{value | currency: currency || ""}
  end

  def new(
        %{
          "margin_free" => margin_free,
          "margin_level" => margin_level
        } = args
      )
      when is_number(margin_free) and is_number(margin_level) do
    value = args |> Map.drop(["margin_free", "margin_level"]) |> new()

    %{value | margin_free: margin_free, margin_level: margin_level}
  end

  def new(
        %{
          "marginFree" => margin_free,
          "marginLevel" => margin_level
        } = args
      )
      when is_number(margin_free) and is_number(margin_level) do
    args
    |> Map.drop(["marginFree", "marginLevel"])
    |> Map.put("margin_free", margin_free)
    |> Map.put("margin_level", margin_level)
    |> new()
  end

  def new(%{
        "balance" => balance,
        "cashStockValue" => cash_stock_value,
        "credit" => credit,
        "equity" => equity,
        "equityFX" => equity_fx,
        "margin" => margin,
        "stockLock" => stock_lock,
        "stockValue" => stock_value
      })
      when is_number(balance) and is_number(cash_stock_value) and is_number(credit) and
             is_number(equity) and is_number(equity_fx) and
             is_number(margin) and
             is_number(stock_lock) and is_number(stock_value) do
    %__MODULE__{
      balance: balance,
      cash_stock_value: cash_stock_value,
      credit: credit,
      currency: nil,
      equity: equity,
      equity_fx: equity_fx,
      margin: margin,
      margin_free: 0.0,
      margin_level: 0.0,
      stock_lock: stock_lock,
      stock_value: stock_value
    }
  end
end
