defmodule XtbClient.Messages.TradingHours do
  @moduledoc """
  Query result for list of `XtbClient.Messages.TradingHour`s.

  ## Parameters
  - `data` array or results.

  ## Handled Api methods
  - `getTradingHours`
  """

  alias XtbClient.Messages.TradingHour

  defmodule Query do
    @moduledoc """
    Info about the query for trading hours.

    ## Parameters
    - `symbols` array of symbol names.
    """

    @type t :: %__MODULE__{
            symbols: [String.t()]
          }

    @enforce_keys [:symbols]
    @derive Jason.Encoder
    defstruct symbols: []

    def new(symbols) when is_list(symbols) do
      %__MODULE__{
        symbols: symbols
      }
    end
  end

  @type t :: %__MODULE__{
          data: [TradingHour.t()]
        }

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
end
