defmodule XtbClient.Messages.Quotations do
  defmodule Query do
    @enforce_keys [:symbol]

    @derive Jason.Encoder
    defstruct symbol: "",
              minArrivalTime: 0,
              maxLevel: nil

    def new(
          %{
            min_arrival_time: min_arrival_time,
            max_level: max_level
          } = args
        )
        when is_integer(min_arrival_time) and is_integer(max_level) do
      value =
        args
        |> Map.delete(:min_arrival_time)
        |> Map.delete(:max_level)
        |> __MODULE__.new()

      %{value | minArrivalTime: min_arrival_time, maxLevel: max_level}
    end

    def new(%{symbol: symbol}) when is_binary(symbol) do
      %__MODULE__{
        symbol: symbol
      }
    end
  end

  alias XtbClient.Messages.TickPrice

  def match(method, data)
      when method in ["getTickPrices"] and is_map(data) and map_size(data) > 1 do
    {:ok, TickPrice.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
