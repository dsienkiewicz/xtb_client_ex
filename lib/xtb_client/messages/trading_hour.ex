defmodule XtbClient.Messages.TradingHour do
  alias XtbClient.Messages.{Quote}

  @enforce_keys [:quotes, :symbol, :trading]

  @derive Jason.Encoder
  defstruct quotes: [],
            symbol: "",
            trading: []

  def new(%{
        "quotes" => quotes,
        "symbol" => symbol,
        "trading" => trading
      })
      when is_list(quotes) and is_binary(symbol) and is_list(trading) do
    %__MODULE__{
      quotes: quotes |> Enum.map(&Quote.new(&1)),
      symbol: symbol,
      trading: trading |> Enum.map(&Quote.new(&1))
    }
  end
end
