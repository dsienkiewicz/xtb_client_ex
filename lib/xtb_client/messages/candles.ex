defmodule XtbClient.Messages.Candles do
  defmodule Query do
    @enforce_keys [:symbol]

    @derive Jason.Encoder
    defstruct symbol: ""

    def new(symbol) when is_binary(symbol) do
      %__MODULE__{symbol: symbol}
    end
  end

  alias XtbClient.Messages.{Candle}

  def match(method, data) when method in ["getCandles"] do
    {:ok, Candle.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
