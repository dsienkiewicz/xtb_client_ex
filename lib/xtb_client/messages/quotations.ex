defmodule XtbClient.Messages.Quotations do
  defmodule Query do
    @moduledoc """
    Info about query for tick prices.

    ## Parameters
    - `symbol` symbol name,
    - `minArrivalTime` this field is optional and defines the minimal interval in milliseconds between any two consecutive updates.
      If this field is not present, or it is set to 0 (zero), ticks - if available - are sent to the client with interval equal to 200 milliseconds.
      In order to obtain ticks as frequently as server allows you, set it to 1 (one).
    - `maxLevel` this field is optional and specifies the maximum level of the quote that the user is interested in.
      If this field is not specified, the subscription is active for all levels that are managed in the system.
    """

    @type t :: %__MODULE__{
            symbol: String.t(),
            minArrivalTime: integer(),
            maxLevel: integer()
          }

    @enforce_keys [:symbol, :minArrivalTime, :maxLevel]
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
      value = args |> Map.drop([:min_arrival_time, :max_level]) |> new()

      %{value | minArrivalTime: min_arrival_time, maxLevel: max_level}
    end

    def new(%{symbol: symbol}) when is_binary(symbol) do
      %__MODULE__{
        symbol: symbol,
        minArrivalTime: 0,
        maxLevel: nil
      }
    end
  end
end
