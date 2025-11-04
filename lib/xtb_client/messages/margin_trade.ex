defmodule XtbClient.Messages.MarginTrade do
  @moduledoc """
  Info about calculated margin in account currency.

  ## Properties
  - `margin` value of margin.

  ## Handled Api methods
  - `getMarginTrade`
  """

  defmodule Query do
    @moduledoc """
    Returns expected margin for given instrument and volume.

    The value is calculated as expected margin value and therefore might not be perfectly accurate.
    """
    alias XtbClient.Messages.MarginTrade
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
    def operation(%__MODULE__{}), do: "getMarginTrade"

    @impl XtbClient.Message
    def encode(%__MODULE__{} = data), do: data.symbol_volume

    @impl XtbClient.Message
    def decode(data), do: MarginTrade.new(data)
  end

  @type t :: %__MODULE__{
          margin: float()
        }

  @enforce_keys [:margin]
  @derive Jason.Encoder
  defstruct margin: 0.0

  def new(%{"margin" => margin}) when is_number(margin) do
    %__MODULE__{
      margin: margin
    }
  end
end
