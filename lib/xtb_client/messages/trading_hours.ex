defmodule XtbClient.Messages.TradingHours do
  @moduledoc """
  Query result for list of `XtbClient.Messages.TradingHour`s.

  ## Parameters
  - `data` array or results.

  ## Handled Api methods
  - `getTradingHours`
  """

  defmodule Query do
    @moduledoc """
    Returns quotes and trading times.

    ## Parameters
    - `symbols` - array of symbol names.
    """
    alias XtbClient.Messages.TradingHours

    @behaviour XtbClient.Message

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

    @impl XtbClient.Message
    def operation(%__MODULE__{}), do: "getTradingHours"

    @impl XtbClient.Message
    def encode(%__MODULE__{} = data), do: data

    @impl XtbClient.Message
    def decode(data), do: TradingHours.new(data)
  end

  alias XtbClient.Messages.TradingHour

  @type t :: %__MODULE__{
          data: [TradingHour.t()]
        }

  @enforce_keys [:data]
  @derive Jason.Encoder
  defstruct data: []

  def new(data) when is_list(data) do
    %__MODULE__{
      data:
        Enum.map(
          data,
          &TradingHour.new(&1)
        )
    }
  end
end
