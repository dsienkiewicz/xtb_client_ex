defmodule XtbClient.Messages.TickPrices do
  @moduledoc """
  Query result for list of `XtbClient.Messages.TickPrice`s.

  ## Parameters
  - `data` array or results.

  ## Handled Api methods
  - `getTickPrices`
  """

  defmodule Query do
    @moduledoc """
    Returns array of current quotations for given symbols, only quotations that changed from given timestamp are returned.

    New timestamp obtained from output will be used as an argument of the next call of this command.

    **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_tick_prices/2` which is the preferred way of retrieving ticks data.**

    ## Parameters
    - `level` - price level (possible values of level field: -1 => all levels, 0 => base level bid and ask price for instrument, >0 => specified level),
    - `symbols` - array of symbol names,
    - `timestamp` - the time from which the most recent tick should be looked for. Historical prices cannot be obtained using this parameter. It can only be used to verify whether a price has changed since the given time.
    """
    alias XtbClient.Messages.TickPrice
    alias XtbClient.Messages.TickPrices

    @behaviour XtbClient.Message

    @type t :: %__MODULE__{
            level: integer(),
            symbols: [String.t()],
            timestamp: integer()
          }

    @enforce_keys [:level, :symbols, :timestamp]
    @derive Jason.Encoder
    defstruct level: nil,
              symbols: [],
              timestamp: nil

    def new(%{
          level: level,
          symbols: [_ | _] = symbols,
          timestamp: %DateTime{} = timestamp
        })
        when is_integer(level) do
      %__MODULE__{
        level: level,
        symbols: symbols,
        timestamp: DateTime.to_unix(timestamp, :millisecond)
      }
    end

    @impl XtbClient.Message
    def operation(%__MODULE__{}), do: "getTickPrices"

    @impl XtbClient.Message
    def encode(%__MODULE__{} = data), do: data

    @impl XtbClient.Message
    def decode(%{"quotations" => data}) when is_list(data), do: TickPrices.new(data)
    def decode(data) when is_map(data) and map_size(data) > 1, do: TickPrice.new(data)
  end

  alias XtbClient.Messages.TickPrice

  @type t :: %__MODULE__{
          data: [TickPrice.t()]
        }

  @enforce_keys [:data]
  @derive Jason.Encoder
  defstruct data: []

  def new(data)
      when is_list(data) do
    %__MODULE__{
      data: Enum.map(data, &TickPrice.new(&1))
    }
  end
end
