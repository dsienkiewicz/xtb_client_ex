defmodule XtbClient.Messages.TradingHour do
  alias XtbClient.Messages.{Quote}

  @moduledoc """
  Info about one available trading hour.

  ## Parameters
  - `quotes` array of `XtbClient.Messages.Quote`s representing available quotes hours,
  - `symbol` symbol name,
  - `trading` array of `XtbClient.Messages.Quote`s representing available trading hours.
  """

  @type t :: %__MODULE__{
          quotes: [Quote.t()],
          symbol: String.t(),
          trading: [Quote.t()]
        }

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
