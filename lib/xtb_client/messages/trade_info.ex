defmodule XtbClient.Messages.TradeInfo do
  alias XtbClient.Messages.Operation

  @enforce_keys [
    :close_price,
    :close_time,
    :closed,
    :operation,
    :comment,
    :commission,
    :custom_comment,
    :digits,
    :expiration,
    :margin_rate,
    :nominal_value,
    :offset,
    :open_price,
    :open_time,
    :order_opened,
    :order_closed,
    :position,
    :profit,
    :stop_loss,
    :storage,
    :symbol,
    :take_profit,
    :volume
  ]

  defstruct close_price: 0.0,
            close_time: nil,
            closed: nil,
            operation: nil,
            comment: "",
            commission: nil,
            custom_comment: "",
            digits: 0,
            expiration: nil,
            margin_rate: 0.0,
            nominal_value: nil,
            offset: 0,
            open_price: 0.0,
            open_time: nil,
            order_opened: 0,
            order_closed: 0,
            position: 0,
            profit: nil,
            stop_loss: 0.0,
            spread: nil,
            state: nil,
            storage: 0.0,
            symbol: "",
            taxes: nil,
            timestamp: nil,
            take_profit: 0.0,
            type: nil,
            volume: 0.0

  def new(
        %{
          "state" => state,
          "type" => type
        } = args
      ) do
    value =
      args
      |> Map.delete("state")
      |> Map.delete("type")
      |> __MODULE__.new()

    %{value | state: state, type: type}
  end

  def new(
        %{
          "spread" => spread,
          "taxes" => taxes,
          "timestamp" => timestamp_value
        } = args
      )
      when is_number(spread) and
             is_number(taxes) and
             is_integer(timestamp_value) do
    value =
      args
      |> Map.delete("spread")
      |> Map.delete("taxes")
      |> Map.delete("timestamp")
      |> __MODULE__.new()

    %{
      value
      | spread: spread,
        taxes: taxes,
        timestamp: DateTime.from_unix!(timestamp_value, :millisecond)
    }
  end

  def new(%{
        "close_price" => close_price,
        "close_time" => close_time_value,
        "closed" => closed,
        "cmd" => operation,
        "comment" => comment,
        "commission" => commission,
        "customComment" => custom_comment,
        "digits" => digits,
        "expiration" => expiration_value,
        "margin_rate" => margin_rate,
        "nominalValue" => nominal_value,
        "offset" => offset,
        "open_price" => open_price,
        "open_time" => open_time_value,
        "order" => order_opened,
        "order2" => order_closed,
        "position" => position,
        "profit" => profit,
        "sl" => stop_loss,
        "storage" => storage,
        "symbol" => symbol,
        "tp" => take_profit,
        "volume" => volume
      })
      when is_number(close_price) and
             is_boolean(closed) and
             is_integer(operation) and
             is_number(commission) and
             is_binary(custom_comment) and
             is_integer(digits) and
             is_number(margin_rate) and
             is_integer(offset) and
             is_number(open_price) and is_integer(open_time_value) and
             is_integer(order_opened) and is_integer(order_closed) and is_integer(position) and
             is_number(stop_loss) and
             is_number(storage) and
             is_binary(symbol) and
             is_number(take_profit) and
             is_number(volume) do
    %__MODULE__{
      close_price: close_price,
      close_time:
        (not is_nil(close_time_value) && DateTime.from_unix!(close_time_value, :millisecond)) ||
          close_time_value,
      closed: closed,
      operation: Operation.parse(operation),
      comment: comment,
      commission: commission,
      custom_comment: custom_comment,
      digits: digits,
      expiration:
        (not is_nil(expiration_value) && DateTime.from_unix!(expiration_value, :millisecond)) ||
          expiration_value,
      margin_rate: margin_rate,
      nominal_value: nominal_value,
      offset: offset,
      open_price: open_price,
      open_time: DateTime.from_unix!(open_time_value, :millisecond),
      order_opened: order_opened,
      order_closed: order_closed,
      position: position,
      profit: profit,
      stop_loss: stop_loss,
      storage: storage,
      symbol: symbol,
      take_profit: take_profit,
      volume: volume
    }
  end
end
