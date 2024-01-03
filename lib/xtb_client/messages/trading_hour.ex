defmodule XtbClient.Messages.TradingHour do
  @moduledoc """
  Info about one available trading hour.

  ## Parameters
  - `quotes` array of `XtbClient.Messages.Quote`s representing available quotes hours,
  - `symbol` symbol name,
  - `trading` array of `XtbClient.Messages.Quote`s representing available trading hours.
  """

  alias XtbClient.Messages.Quote

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
      when is_list(quotes) and is_list(trading) do
    %__MODULE__{
      quotes: Enum.map(quotes, &Quote.new(&1)),
      symbol: symbol || "",
      trading: Enum.map(trading, &Quote.new(&1))
    }
  end
end
