defmodule XtbClient.Messages.TradeTransactionStatus do
  @moduledoc """
  Info about the status of particular transaction.

  ## Parameters
  - `ask` price in base currency,
  - `bid` price in base currency,
  - `custom_comment` the value the customer may provide in order to retrieve it later,
  - `message` can be `null`,
  - `order` unique order number,
  - `status` request status code, see `XtbClient.Messages.TradeStatus`.

  ## Handled Api methods
  - `tradeTransactionStatus`
  """

  defmodule Query do
    @moduledoc """
    Returns current transaction status.

    At any time of transaction processing client might check the status of transaction on server side.
    In order to do that client must provide unique order taken from `trade_transaction/2` invocation.

    ## Parameters
    - `order` - unique order number.
    """
    alias XtbClient.Messages.TradeTransactionStatus

    @behaviour XtbClient.Message

    @type t :: %__MODULE__{
            order: integer()
          }

    @enforce_keys [:order]
    @derive Jason.Encoder
    defstruct order: 0

    def new(order) when is_integer(order) do
      %__MODULE__{
        order: order
      }
    end

    @impl XtbClient.Message
    def operation(%__MODULE__{}), do: "tradeTransactionStatus"

    @impl XtbClient.Message
    def encode(%__MODULE__{} = data), do: data

    @impl XtbClient.Message
    def decode(data), do: TradeTransactionStatus.new(data)
  end

  alias XtbClient.Messages.TransactionStatus

  @type t :: %__MODULE__{
          ask: float(),
          bid: float(),
          custom_comment: String.t(),
          message: String.t() | nil,
          order: integer(),
          status: TransactionStatus.t()
        }

  @enforce_keys [:ask, :bid, :custom_comment, :message, :order, :status]
  @derive Jason.Encoder
  defstruct ask: 0.0,
            bid: 0.0,
            custom_comment: "",
            message: nil,
            order: 0,
            status: nil

  def new(%{
        "ask" => ask,
        "bid" => bid,
        "customComment" => comment,
        "message" => message,
        "order" => order,
        "requestStatus" => status
      })
      when is_number(ask) and is_number(bid) and
             is_integer(order) and is_integer(status) do
    %__MODULE__{
      ask: ask,
      bid: bid,
      custom_comment: comment || "",
      message: message || "",
      order: order,
      status: TransactionStatus.parse(status)
    }
  end
end
