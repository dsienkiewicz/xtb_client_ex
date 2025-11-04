defmodule XtbClient.Messages.TradeStatus do
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

  defmodule SubscribeTradeStatusCommand do
    @moduledoc """
    Command for subscribing to trade status updates.
    """
    alias XtbClient.Messages.TradeStatus

    @behaviour XtbClient.StreamingMessage

    @type t :: %__MODULE__{
            metadata: map() | nil
          }

    @derive {Jason.Encoder, except: [:metadata]}
    defstruct metadata: nil

    def new(metadata \\ nil), do: %__MODULE__{metadata: metadata}

    @impl XtbClient.StreamingMessage
    def operation(%__MODULE__{}), do: "getTradeStatus"

    @impl XtbClient.StreamingMessage
    def response_path(%__MODULE__{}), do: "tradeStatus"

    @impl XtbClient.StreamingMessage
    def encode(%__MODULE__{} = data), do: data

    @impl XtbClient.StreamingMessage
    def decode(data), do: TradeStatus.new(data)

    @impl XtbClient.StreamingMessage
    def hash(%__MODULE__{}), do: "tradeStatus"

    @impl XtbClient.StreamingMessage
    def fetch_metadata(%__MODULE__{} = data), do: data.metadata
  end

  defmodule UnsubscribeTradeStatusCommand do
    @moduledoc """
    Command for unsubscribing from trade status updates.
    """
    @behaviour XtbClient.StreamingMessage

    @type t :: %__MODULE__{}

    @derive Jason.Encoder
    defstruct []

    def new, do: %__MODULE__{}

    @impl XtbClient.StreamingMessage
    def operation(%__MODULE__{}), do: "stopTradeStatus"

    @impl XtbClient.StreamingMessage
    def response_path(%__MODULE__{}), do: "tradeStatus"

    @impl XtbClient.StreamingMessage
    def encode(%__MODULE__{} = data), do: data

    @impl XtbClient.StreamingMessage
    def decode(data), do: data

    @impl XtbClient.StreamingMessage
    def hash(%__MODULE__{}), do: "tradeStatus"

    @impl XtbClient.StreamingMessage
    def fetch_metadata(%__MODULE__{}), do: nil
  end

  alias XtbClient.Messages.TransactionStatus

  @type t :: %__MODULE__{
          custom_comment: String.t(),
          message: String.t(),
          order: integer(),
          price: float(),
          status: TransactionStatus.t()
        }

  @enforce_keys [:custom_comment, :message, :order, :price, :status]
  @derive Jason.Encoder
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
      when is_integer(order) and is_number(price) and
             is_integer(status) do
    %__MODULE__{
      custom_comment: comment || "",
      message: message,
      order: order,
      price: price,
      status: TransactionStatus.parse(status)
    }
  end
end
