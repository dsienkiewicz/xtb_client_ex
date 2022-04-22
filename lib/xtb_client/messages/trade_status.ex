defmodule XtbClient.Messages.TradeStatus do
  alias XtbClient.Messages.TransactionStatus

  @moduledoc """
  Info about the actual status of sent trade request.
  
  ## Parameters
  - `custom_comment` the value the customer may provide in order to retrieve it later,
  - `message` message, can be `null`,
  - `order` unique order number,
  - `price` price in base currency,
  - `status` request status code, see `XtbClient.Messages.TransactionStatus`.
  
  ## Handled Api methods
  - `getTradeStatus`
  """

  @type t :: %__MODULE__{
          custom_comment: binary(),
          message: binary(),
          order: integer(),
          price: float(),
          status: TransactionStatus.t()
        }

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
