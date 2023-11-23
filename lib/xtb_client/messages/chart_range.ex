defmodule XtbClient.Messages.ChartRange do
  defmodule Query do
    @moduledoc """
    Parameters for chart range query.

    ## Parameters
    - `start` start of chart block (rounded down to the nearest interval and excluding),
    - `end` end of chart block (rounded down to the nearest interval and excluding),
    - `period` period, see `XtbClient.Messages.Period`,
    - `symbol` symbol name,
    - `ticks` number of ticks needed, this field is optional, please read the description below.

    ## Ticks
    Ticks field - if ticks is not set or value is `0`, `getChartRangeRequest` works as before (you must send valid start and end time fields).
    If ticks value is not equal to `0`, field end is ignored.
    If ticks `>0` (e.g. `N`) then API returns `N` candles from time start.
    If ticks `<0` then API returns `N` candles to time start.
    It is possible for API to return fewer chart candles than set in tick field.
    """

    alias XtbClient.Messages.{DateRange, Period}

    @type t :: %__MODULE__{
            start: integer(),
            end: integer(),
            period: Period.t(),
            symbol: String.t(),
            ticks: integer()
          }

    @enforce_keys [:start, :end, :period, :symbol, :ticks]
    @derive Jason.Encoder
    defstruct start: nil,
              end: nil,
              period: :h1,
              symbol: "",
              ticks: 0

    def new(%{ticks: ticks} = args)
        when is_number(ticks) do
      value = args |> Map.drop([:ticks]) |> new()

      %{value | ticks: ticks}
    end

    def new(%{
          range: %DateRange{start: start, end: end_value},
          period: period,
          symbol: symbol
        })
        when is_atom(period) and is_binary(symbol) do
      %__MODULE__{
        start: start,
        end: end_value,
        period: Period.format(period),
        symbol: symbol,
        ticks: 0
      }
    end
  end
end
