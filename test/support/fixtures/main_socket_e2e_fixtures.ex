defmodule XtbClient.MainSocket.E2EFixtures do
  @moduledoc false

  alias XtbClient.MainSocket
  alias XtbClient.Messages.{Trades, TradeTransaction}

  def open_trade(pid, buy_args) do
    buy_command = TradeTransaction.Command.new(buy_args)
    MainSocket.handle_query(pid, buy_command)
  end

  def close_trade(pid, open_order_id, close_args) do
    # 1. way - get all opened only trades
    trades_query = Trades.TradesQuery.new(true)
    {:ok, result} = MainSocket.handle_query(pid, trades_query)

    position_to_close = Enum.find(result.data, &(&1.order_closed == open_order_id))

    close_args =
      Map.merge(
        close_args,
        %{
          price: 0.01,
          order: position_to_close.order_opened
        }
      )

    close_command = TradeTransaction.Command.new(close_args)
    MainSocket.handle_query(pid, close_command)
  end
end
