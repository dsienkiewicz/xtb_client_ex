defmodule XtbClient.Messages.ChartLast do
  defmodule Query do
    @moduledoc """
    Returns chart info from start date to the current time.

    If the chosen period of `XtbClient.Messages.ChartLast.Query` is greater than 1 minute, the last candle returned by the API can change until the end of the period (the candle is being automatically updated every minute).

    Limitations: there are limitations in charts data availability. Detailed ranges for charts data, what can be accessed with specific period, are as follows:

    - PERIOD_M1 --- <0-1) month, i.e. one month time
    - PERIOD_M30 --- <1-7) month, six months time
    - PERIOD_H4 --- <7-13) month, six months time
    - PERIOD_D1 --- 13 month, and earlier on

    Note, that specific PERIOD_ is the lowest (i.e. the most detailed) period, accessible in listed range. For instance, in months range <1-7) you can access periods: PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1.
    Specific data ranges availability is guaranteed, however those ranges may be wider, e.g.: PERIOD_M1 may be accessible for 1.5 months back from now, where 1.0 months is guaranteed.

    ## Example scenario:

    * request charts of 5 minutes period, for 3 months time span, back from now;
    * response: you are guaranteed to get 1 month of 5 minutes charts; because, 5 minutes period charts are not accessible 2 months and 3 months back from now

    **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_candles/2` which is the preferred way of retrieving current candle data.**

    ## Parameters
    - `period` - an atom of `XtbClient.Messages.Period` type, describing the time interval for the query
    - `start` - start of chart block (rounded down to the nearest interval and excluding)
    - `symbol` - symbol name.
    """
    alias XtbClient.Messages.Period
    alias XtbClient.Messages.RateInfos

    @behaviour XtbClient.Message

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
            :symbol => String.t()
          }) :: XtbClient.Messages.ChartLast.Query.t()
    def new(%{period: period, start: start, symbol: symbol})
        when is_atom(period) and not is_nil(start) and is_binary(symbol) do
      %__MODULE__{
        period: Period.format(period),
        start: DateTime.to_unix(start, :millisecond),
        symbol: symbol
      }
    end

    @impl XtbClient.Message
    def operation(%__MODULE__{}), do: "getChartLastRequest"

    @impl XtbClient.Message
    def encode(%__MODULE__{} = data), do: %{info: data}

    @impl XtbClient.Message
    def decode(data), do: RateInfos.new(data)
  end
end
