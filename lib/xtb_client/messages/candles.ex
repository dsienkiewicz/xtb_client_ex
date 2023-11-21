defmodule XtbClient.Messages.Candles do
  defmodule Query do
    @moduledoc """
    Info about query for candles.

    ## Parameters
    - `symbol` symbol name.
    """

    @type t :: %__MODULE__{
            symbol: String.t()
          }

    @enforce_keys [:symbol]
    @derive Jason.Encoder
    defstruct symbol: ""

    def new(symbol) when is_binary(symbol) do
      %__MODULE__{symbol: symbol}
    end
  end
end
