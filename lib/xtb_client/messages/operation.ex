defmodule XtbClient.Messages.Operation do
  @moduledoc """
  Atoms for operation codes.
  """

  @type t ::
          :buy
          | :sell
          | :buy_limit
          | :sell_limit
          | :buy_stop
          | :sell_stop
          | :balance
          | :credit

  @type operation_code :: 0..7

  @doc """
  Parse an integer number as valid operation atom.
  """
  @spec parse(operation_code()) :: t()
  def parse(value) when value in 0..7 do
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

  @doc """
  Format operation atom as integer value.
  """
  @spec format(t()) :: operation_code()
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
