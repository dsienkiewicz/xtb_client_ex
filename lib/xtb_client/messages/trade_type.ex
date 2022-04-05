defmodule XtbClient.Messages.TradeType do
  @moduledoc """
  Atoms for operation types.
  
  Values:
  - `:open` order open, used for opening orders,
  - `:pending` order pending, only used in the streaming `XtbClient.Connection.subscribe_get_trades/2` command,
  - `:close` order close,
  - `:modify` order modify, only used in the `XtbClient.Connection.trade_transaction/2` command,
  - `:delete` order delete, only used in the `XtbClient.Connection.trade_transaction/2` command.
  """

  @type t :: :open | :pending | :close | :modify | :delete

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
