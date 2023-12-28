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

  @doc """
  Parse integer value as valid atom for trade type.
  """
  @spec parse(value :: trade_code()) :: t()
  def parse(value) when value in [0, 1, 2, 3, 4] do
    parse_type(value)
  end

  defp parse_type(value) do
    case value do
      0 -> :open
      1 -> :pending
      2 -> :close
      3 -> :modify
      4 -> :delete
    end
  end

  @doc """
  Format atom representing trade type to integer value.
  """
  @spec format(type :: t()) :: trade_code()
  def format(type) when is_atom(type) do
    format_type(type)
  end

  defp format_type(type) do
    case type do
      :open -> 0
      :pending -> 1
      :close -> 2
      :modify -> 3
      :delete -> 4
    end
  end
end
