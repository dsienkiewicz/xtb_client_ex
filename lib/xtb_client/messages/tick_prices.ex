defmodule XtbClient.Messages.TickPrices do
  defmodule Query do
    @enforce_keys [:level, :symbols, :timestamp]

    @derive Jason.Encoder
    defstruct level: nil,
              symbols: [],
              timestamp: nil

    def new(%{
          level: level,
          symbols: symbols,
          timestamp: timestamp
        })
        when is_integer(level) and is_list(symbols) and not is_nil(timestamp) do
      %__MODULE__{
        level: level,
        symbols: symbols,
        timestamp: DateTime.to_unix(timestamp, :millisecond)
      }
    end
  end

  alias XtbClient.Messages.TickPrice
  @enforce_keys [:data]

  defstruct data: []

  def new(data)
      when is_list(data) do
    %__MODULE__{
      data:
        data
        |> Enum.map(&TickPrice.new(&1))
    }
  end

  def match(method, %{"quotations" => data}) when method in ["getTickPrices"] and is_list(data) do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
