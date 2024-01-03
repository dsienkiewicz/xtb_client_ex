defmodule XtbClient.Messages.TradeType do
  @moduledoc """
  Atoms representing operation types.

  ## Values
  - `:open` order open, used for opening orders,
  - `:pending` order pending, only used in the streaming `XtbClient.Connection.subscribe_get_trades/2` command,
  - `:close` order close,
  - `:modify` order modify, only used in the `XtbClient.Connection.trade_transaction/2` command,
  - `:delete` order delete, only used in the `XtbClient.Connection.trade_transaction/2` command.
  """

  @type t :: :open | :pending | :close | :modify | :delete
  @type trade_code :: 0..4

  @map [
    open: 0,
    pending: 1,
    close: 2,
    modify: 3,
    delete: 4
  ]

  @doc """
  Parse integer value as valid atom for trade type.
  """
  @spec parse(value :: trade_code()) :: t()
  for {type, value} <- @map do
    def parse(unquote(value)), do: unquote(type)
  end

  @doc """
  Format atom representing trade type to integer value.
  """
  @spec format(type :: t()) :: trade_code()
  for {type, value} <- @map do
    def format(unquote(type)), do: unquote(value)
  end
end
