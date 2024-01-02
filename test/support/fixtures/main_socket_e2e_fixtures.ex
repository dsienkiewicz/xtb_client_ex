defmodule XtbClient.MainSocket.E2EFixtures do
  @moduledoc false

  alias XtbClient.MainSocket
  alias XtbClient.Messages

  def poll_stream_session_id(server) do
    case MainSocket.stream_session_id(server) do
      {:ok, nil} ->
        Process.sleep(100)
        poll_stream_session_id(server)

      {:ok, _session_id} = result ->
        result
    end
  end

  def open_trade(pid, buy_args) do
    buy = Messages.TradeTransaction.Command.new(buy_args)
    MainSocket.trade_transaction(pid, buy)
  end

  def close_trade(pid, open_order_id, close_args) do
    # 1. way - get all opened only trades
    trades_query = Messages.Trades.Query.new(true)
    {:ok, result} = MainSocket.get_trades(pid, trades_query)

    position_to_close = Enum.find(result.data, &(&1.order_closed == open_order_id))

    close_args =
      Map.merge(
        close_args,
        %{
          price: position_to_close.open_price - 0.01,
          order: position_to_close.order_opened
        }
      )

    close = Messages.TradeTransaction.Command.new(close_args)
    MainSocket.trade_transaction(pid, close)
  end
end
