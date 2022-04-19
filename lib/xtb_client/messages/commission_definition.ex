defmodule XtbClient.Messages.CommissionDefinition do
  @moduledoc """
  Query result for commission definition.
  
  ## Parameters
  - `commission` calculated commission in account currency,
  - `rate_of_exchange` rate of exchange between account currency and instrument base currency.
  
  ## Handled Api methods
  - `getCommissionDef`
  """

  @type t :: %__MODULE__{
          commission: float(),
          rate_of_exchange: float()
        }

  @enforce_keys [:commission, :rate_of_exchange]

  @derive Jason.Encoder
  defstruct commission: 0.0,
            rate_of_exchange: 0.0

  def new(%{"commission" => commission, "rateOfExchange" => rate_of_exchange})
      when is_number(commission) and is_number(rate_of_exchange) do
    %__MODULE__{
      commission: commission,
      rate_of_exchange: rate_of_exchange
    }
  end

  def match(method, data) when method in ["getCommissionDef"] do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
