defmodule XtbClient.Messages.TickPrices do
  defmodule Query do
    @moduledoc """
    Info about the query for tick prices.
    
    ## Parameters
    - `level` price level (possible values of level field: -1 => all levels, 0 => base level bid and ask price for instrument, >0 => specified level),
    - `symbols` array of symbol names,
    - `timestamp` the time from which the most recent tick should be looked for. Historical prices cannot be obtained using this parameter. It can only be used to verify whether a price has changed since the given time.
    """

    @type t :: %__MODULE__{
            level: integer(),
            symbols: [binary()],
            timestamp: integer()
          }

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

  @moduledoc """
  Query result for list of `XtbClient.Messages.TickPrice`s.
  
  ## Parameters
  - `data` array or results.
  
  ## Handled Api methods
  - `getTickPrices`
  """

  @type t :: %__MODULE__{
          data: [TickPrice.t()]
        }

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
