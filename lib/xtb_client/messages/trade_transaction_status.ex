defmodule XtbClient.Messages.TradeTransactionStatus do
  defmodule Query do
    @enforce_keys [:order]

    @derive Jason.Encoder
    defstruct order: 0

    def new(order) when is_integer(order) do
      %__MODULE__{
        order: order
      }
    end
  end

  alias XtbClient.Messages.TransactionStatus

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
             is_binary(comment) and
             is_integer(order) and is_integer(status) do
    %__MODULE__{
      ask: ask,
      bid: bid,
      custom_comment: comment,
      message: message,
      order: order,
      status: TransactionStatus.parse(status)
    }
  end

  def match(%{"order" => _, "requestStatus" => _} = data) do
    {:ok, __MODULE__.new(data)}
  end

  def match(_data) do
    {:no_match}
  end
end

defmodule XtbClient.Messages.TransactionStatus do
  def parse(value) when is_number(value) do
    parse_status(value)
  end

  defp parse_status(value) do
    case value do
      0 -> :error
      1 -> :pending
      3 -> :accepted
      4 -> :rejected
    end
  end
end
