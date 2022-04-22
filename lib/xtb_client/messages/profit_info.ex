defmodule XtbClient.Messages.ProfitInfo do
  @moduledoc """
  Result of profit calculation.
  
  ## Parameters
  - `order_id` order number,
  - `transaction_id` transaction ID,
  - `position_no` position number,
  - `profit` profit in account currency,
  - `market_value` market value,
  - `profit_calc_price` profit calc price,
  - `profit_recalc_price` profit recalc price.
  
  ## Handled Api methods
  - `getProfits`
  """

  @type t :: %__MODULE__{
          order_id: integer(),
          transaction_id: integer(),
          position_no: integer(),
          profit: float(),
          market_value: float(),
          profit_calc_price: float(),
          profit_recalc_price: float()
        }

  @enforce_keys [
    :order_id,
    :transaction_id,
    :position_no,
    :profit,
    :market_value,
    :profit_calc_price,
    :profit_recalc_price
  ]

  @derive Jason.Encoder
  defstruct order_id: nil,
            transaction_id: nil,
            position_no: nil,
            profit: 0.0,
            market_value: 0.0,
            profit_calc_price: 0.0,
            profit_recalc_price: 0.0

  def new(%{
        "order" => order,
        "order2" => transaction,
        "position" => position,
        "profit" => profit,
        "marketValue" => market_value,
        "profitCalcPrice" => profit_calc_price,
        "profitRecalcPrice" => profit_recalc_price
      })
      when is_number(order) and is_number(transaction) and is_number(position) and
             is_number(profit) and
             is_number(market_value) and
             is_number(profit_calc_price) and is_number(profit_recalc_price) do
    %__MODULE__{
      order_id: order,
      transaction_id: transaction,
      position_no: position,
      profit: profit,
      market_value: market_value,
      profit_calc_price: profit_calc_price,
      profit_recalc_price: profit_recalc_price
    }
  end

  def match(method, data) when method in ["getProfits"] do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
