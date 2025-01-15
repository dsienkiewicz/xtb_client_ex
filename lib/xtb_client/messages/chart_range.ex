defmodule XtbClient.Messages.ChartRange do
  defmodule Query do
    @moduledoc """
    Returns chart info with data between given start and end dates.

    Limitations: there are limitations in charts data availability. Detailed ranges for charts data, what can be accessed with specific period, are as follows:

    - PERIOD_M1 --- <0-1) month, i.e. one month time
    - PERIOD_M30 --- <1-7) month, six months time
    - PERIOD_H4 --- <7-13) month, six months time
    - PERIOD_D1 --- 13 month, and earlier on

    Note, that specific PERIOD_ is the lowest (i.e. the most detailed) period, accessible in listed range. For instance, in months range <1-7) you can access periods: PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1.
    Specific data ranges availability is guaranteed, however those ranges may be wider, e.g.: PERIOD_M1 may be accessible for 1.5 months back from now, where 1.0 months is guaranteed.

    **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_candles/2` which is the preferred way of retrieving current candle data.**

    ## Parameters
    - `start` - start of chart block (rounded down to the nearest interval and excluding),
    - `end` - end of chart block (rounded down to the nearest interval and excluding),
    - `period` - period, see `XtbClient.Messages.Period`,
    - `symbol` - symbol name,
    - `ticks` - number of ticks needed, this field is optional, please read the description below.

    ## Ticks
    Ticks field - if ticks is not set or value is `0`, `getChartRangeRequest` works as before (you must send valid start and end time fields).
    If ticks value is not equal to `0`, field end is ignored.
    If ticks `>0` (e.g. `N`) then API returns `N` candles from time start.
    If ticks `<0` then API returns `N` candles to time start.
    It is possible for API to return fewer chart candles than set in tick field.
    """
    alias XtbClient.Messages.DateRange
    alias XtbClient.Messages.Period
    alias XtbClient.Messages.RateInfos

    import Period

    @behaviour XtbClient.Message

    @type t :: %__MODULE__{
            start: integer(),
            end: integer(),
            period: Period.minute_period(),
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
        when is_period(period) and is_binary(symbol) do
      %__MODULE__{
        start: start,
        end: end_value,
        period: Period.format(period),
        symbol: symbol,
        ticks: 0
      }
    end

    @impl XtbClient.Message
    def operation(%__MODULE__{}), do: "getChartRangeRequest"

    @impl XtbClient.Message
    def encode(%__MODULE__{} = data), do: %{info: data}

    @impl XtbClient.Message
    def decode(data), do: RateInfos.new(data)
  end
end
