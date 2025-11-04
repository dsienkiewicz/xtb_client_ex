defmodule XtbClient.Messages.CommissionDefinition do
  @moduledoc """
  Query result for commission definition.

  ## Parameters
  - `commission` calculated commission in account currency,
  - `rate_of_exchange` rate of exchange between account currency and instrument base currency.

  ## Handled Api methods
  - `getCommissionDef`
  """

  defmodule Query do
    @moduledoc """
    Returns calculation of commission and rate of exchange.

    The value is calculated as expected value and therefore might not be perfectly accurate.
    """
    alias XtbClient.Messages.CommissionDefinition
    alias XtbClient.Messages.SymbolVolume

    @behaviour XtbClient.Message

    @type t :: %__MODULE__{symbol_volume: SymbolVolume.t()}

    @enforce_keys [:symbol_volume]
    @derive Jason.Encoder
    defstruct symbol_volume: nil

    def new(%SymbolVolume{} = symbol_volume) do
      %__MODULE__{symbol_volume: symbol_volume}
    end

    @impl XtbClient.Message
    def operation(%__MODULE__{}), do: "getCommissionDef"

    @impl XtbClient.Message
    def encode(%__MODULE__{} = data), do: data.symbol_volume

    @impl XtbClient.Message
    def decode(data), do: CommissionDefinition.new(data)
  end

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
end
