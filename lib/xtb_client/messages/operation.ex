defmodule XtbClient.Messages.Operation do
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
