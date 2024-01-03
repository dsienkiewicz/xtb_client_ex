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

  @map [
    buy: 0,
    sell: 1,
    buy_limit: 2,
    sell_limit: 3,
    buy_stop: 4,
    sell_stop: 5,
    balance: 6,
    credit: 7
  ]

  @doc """
  Parse an integer number as valid operation atom.
  """
  @spec parse(value :: operation_code()) :: t()
  for {operation, value} <- @map do
    def parse(unquote(value)), do: unquote(operation)
  end

  @doc """
  Format operation atom as integer value.
  """
  @spec format(operation :: t()) :: operation_code()
  for {operation, value} <- @map do
    def format(unquote(operation)), do: unquote(value)
  end
end
