defmodule XtbClient.Messages.ChartLast do
  defmodule Query do
    alias XtbClient.Messages.Period

    @enforce_keys [:period, :start, :symbol]

    @derive Jason.Encoder
    defstruct period: :h1,
              start: 0,
              symbol: ""

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
