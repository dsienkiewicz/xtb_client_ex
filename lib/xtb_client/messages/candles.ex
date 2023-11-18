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

  alias XtbClient.Messages.{Candle}

  @moduledoc """
  Query result for `XtbClient.Messages.Candle`s.

  Returns one `XtbClient.Messages.Candle` at a time.

  ## Handled Api methods
  - `getCandles`
  """

  def match(method, data) when method in ["getCandles"] do
    {:ok, Candle.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
