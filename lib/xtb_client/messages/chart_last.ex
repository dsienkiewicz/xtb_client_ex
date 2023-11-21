defmodule XtbClient.Messages.ChartLast do
  defmodule Query do
    alias XtbClient.Messages.Period

    @moduledoc """
    Parameters for last chart query.

    ## Parameters
    - `period` an atom of `XtbClient.Messages.Period` type, describing the time interval for the query
    - `start` start of chart block (rounded down to the nearest interval and excluding)
    - `symbol` symbol name.
    """

    @type t :: %__MODULE__{
            period: Period.minute_period(),
            start: integer(),
            symbol: String.t()
          }

    @enforce_keys [:period, :start, :symbol]

    @derive Jason.Encoder
    defstruct period: :h1,
              start: 0,
              symbol: ""

    @doc """
    Creates new query with mandatory arguments.
    """
    @spec new(%{
            :period => Period.t(),
            :start => Calendar.datetime(),
            :symbol => binary
          }) :: XtbClient.Messages.ChartLast.Query.t()
    def new(%{period: period, start: start, symbol: symbol})
        when is_atom(period) and not is_nil(start) and is_binary(symbol) do
      %__MODULE__{
        period: Period.format(period),
        start: DateTime.to_unix(start, :millisecond),
        symbol: symbol
      }
    end
  end
end
