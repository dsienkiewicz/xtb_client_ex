defmodule XtbClient.TransactionHelper do
  @moduledoc false
  alias XtbClient.Connection

  alias XtbClient.Messages.{
    TradeTransaction,
    Trades
  }

  def open_trade(pid, buy_args) do
    buy = TradeTransaction.Command.new(buy_args)
    result = Connection.trade_transaction(pid, buy)

    result.order
  end

  def close_trade(pid, open_order_id, close_args) do
    # 1. way - get all opened only trades
    trades_query = Trades.Query.new(true)
    result = Connection.get_trades(pid, trades_query)

    position_to_close =
      result.data
      |> Enum.find(&(&1.order_closed == open_order_id))

    close_args =
      close_args
      |> Map.merge(%{
        price: position_to_close.open_price - 0.01,
        order: position_to_close.order_opened
      })

    close = TradeTransaction.Command.new(close_args)
    Connection.trade_transaction(pid, close)
  end
end
