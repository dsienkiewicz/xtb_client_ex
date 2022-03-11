defmodule XtbClient.Messages.TradingHours do
  defmodule Query do
    @enforce_keys [:symbols]

    @derive Jason.Encoder
    defstruct symbols: []

    def new(symbols) when is_list(symbols) do
      %__MODULE__{
        symbols: symbols
      }
    end
  end

  alias XtbClient.Messages.TradingHour
  @enforce_keys [:data]

  @derive Jason.Encoder
  defstruct data: []

  def new(data) when is_list(data) do
    %__MODULE__{
      data:
        data
        |> Enum.map(&TradingHour.new(&1))
    }
  end

  def match(method, data) when method in ["getTradingHours"] do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
