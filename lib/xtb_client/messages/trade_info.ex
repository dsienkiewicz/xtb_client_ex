defmodule XtbClient.Messages.TradeInfo do
  alias XtbClient.Messages.Operation

  defstruct close_price: 0.0,
            close_time: nil,
            close_time_string: "",
            closed: nil,
            operation: nil,
            comment: "",
            commission: nil,
            custom_comment: "",
            digits: 0,
            expiration: nil,
            expiration_string: "",
            margin_rate: 0.0,
            nominal_value: 0.0,
            offset: 0,
            open_price: 0.0,
            open_time: nil,
            open_time_string: "",
            order_opened: 0,
            order_closed: 0,
            position: 0,
            profit: 0.0,
            stop_loss: 0.0,
            spread: 0.0,
            storage: 0.0,
            symbol: "",
            taxes: 0.0,
            timestamp: nil,
            take_profit: 0.0,
            volume: 0.0

  def new(%{
        "close_price" => close_price,
        "close_time" => close_time_value,
        "close_timeString" => close_time_string,
        "closed" => closed,
        "cmd" => operation,
        "comment" => comment,
        "customComment" => custom_comment,
        "commission" => commission,
        "digits" => digits,
        "expiration" => expiration_value,
        "expirationString" => expiration_string,
        "margin_rate" => margin_rate,
        "nominalValue" => nominal_value,
        "offset" => offset,
        "open_price" => open_price,
        "open_time" => open_time_value,
        "open_timeString" => open_time_string,
        "order" => order_opened,
        "order2" => order_closed,
        "position" => position,
        "profit" => profit,
        "sl" => stop_loss,
        "spread" => spread,
        "storage" => storage,
        "symbol" => symbol,
        "taxes" => taxes,
        "timestamp" => timestamp_value,
        "tp" => take_profit,
        "volume" => volume
      })
      when is_number(close_price) and is_boolean(closed) and
             is_integer(operation) and
             is_binary(comment) and is_binary(custom_comment) and
             is_number(commission) and is_integer(digits) and is_number(margin_rate) and
             is_integer(offset) and
             is_number(open_price) and is_integer(open_time_value) and is_binary(open_time_string) and
             is_integer(order_opened) and is_integer(order_closed) and is_integer(position) and
             is_number(profit) and is_number(stop_loss) and is_number(spread) and
             is_number(storage) and
             is_binary(symbol) and is_number(taxes) and is_integer(timestamp_value) and
             is_number(take_profit) and is_number(volume) do
    %__MODULE__{
      close_price: close_price,
      close_time:
        (not is_nil(close_time_value) && DateTime.from_unix!(close_time_value, :millisecond)) ||
          close_time_value,
      close_time_string: close_time_string,
      closed: closed,
      operation: Operation.parse(operation),
      comment: comment,
      commission: commission,
      custom_comment: custom_comment,
      digits: digits,
      expiration:
        (not is_nil(expiration_value) && DateTime.from_unix!(expiration_value, :millisecond)) ||
          expiration_value,
      expiration_string: expiration_string,
      margin_rate: margin_rate,
      nominal_value: nominal_value,
      offset: offset,
      open_price: open_price,
      open_time: DateTime.from_unix!(open_time_value, :millisecond),
      open_time_string: open_time_string,
      order_opened: order_opened,
      order_closed: order_closed,
      position: position,
      profit: profit,
      stop_loss: stop_loss,
      spread: spread,
      storage: storage,
      symbol: symbol,
      taxes: taxes,
      timestamp: DateTime.from_unix!(timestamp_value, :millisecond),
      take_profit: take_profit,
      volume: volume
    }
  end
end
