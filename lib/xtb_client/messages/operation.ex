defmodule XtbClient.Messages.Operation do
  def parse(value) when is_integer(value) do
    parse_operation(value)
  end

  defp parse_operation(value) do
    case value do
      0 -> :buy
      1 -> :sell
      2 -> :buy_limit
      3 -> :sell_limit
      4 -> :buy_stop
      5 -> :sell_stop
      6 -> :balance
      7 -> :credit
    end
  end

  def format(operation) when is_atom(operation) do
    format_operation(operation)
  end

  defp format_operation(operation) do
    case operation do
      :buy -> 0
      :sell -> 1
      :buy_limit -> 2
      :sell_limit -> 3
      :buy_stop -> 4
      :sell_stop -> 5
      :balance -> 6
      :credit -> 7
    end
  end
end
