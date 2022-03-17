defmodule XtbClient.Messages.TradeStatus do
  alias XtbClient.Messages.TransactionStatus

  defstruct custom_comment: "",
            message: nil,
            order: 0,
            price: 0.0,
            status: nil

  def new(%{
        "customComment" => comment,
        "message" => message,
        "order" => order,
        "price" => price,
        "requestStatus" => status
      })
      when is_binary(comment) and
             is_integer(order) and is_number(price) and
             is_integer(status) do
    %__MODULE__{
      custom_comment: comment,
      message: message,
      order: order,
      price: price,
      status: TransactionStatus.parse(status)
    }
  end

  def match(method, data) when method in ["getTradeStatus"] do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
