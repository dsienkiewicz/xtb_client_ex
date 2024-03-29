defmodule XtbClient.Messages.SymbolVolume do
  @moduledoc """
  Info about symbol ticker + volume.

  ## Parameters
  - `symbol` symbol name,
  - `volume` volume in lots.
  """

  @type t :: %__MODULE__{
          symbol: String.t(),
          volume: float()
        }

  @enforce_keys [:symbol, :volume]
  @derive Jason.Encoder
  defstruct symbol: "",
            volume: 0.0

  def new(%{symbol: symbol, volume: volume})
      when is_number(volume) do
    %__MODULE__{
      symbol: symbol || "",
      volume: volume
    }
  end
end
