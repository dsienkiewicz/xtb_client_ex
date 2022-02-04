defmodule XtbClient.Messages.ChartRange do
  defmodule Query do
    alias XtbClient.Messages.Period

    @enforce_keys [:start, :end, :period, :symbol]

    @derive Jason.Encoder
    defstruct start: nil,
              end: nil,
              period: :h1,
              symbol: "",
              ticks: 0

    def new(%{ticks: ticks} = args)
        when is_number(ticks) do
      value = __MODULE__.new(Map.delete(args, :ticks))
      %{value | ticks: ticks}
    end

    def new(%{start: start, end: end_value, period: period, symbol: symbol})
        when not is_nil(start) and not is_nil(end_value) and is_atom(period) and is_binary(symbol) do
      %__MODULE__{
        start: DateTime.to_unix(start, :millisecond),
        end: DateTime.to_unix(end_value, :millisecond),
        period: Period.format(period),
        symbol: symbol
      }
    end
  end
end
