defmodule XtbClient.Messages.TradeInfos do
  @moduledoc """
  Query result for list of `XtbClient.Messages.TradeInfo`s.

  ## Parameters
  - `data` array or results.

  ## Handled Api methods
  - `getTradeRecords`
  - `getTrades`
  - `getTradesHistory`
  """

  defmodule Query do
    @moduledoc """
    Returns array of trades listed in orders query.

    ## Parameters
    - `orders` - array of order IDs.
    """
    alias XtbClient.Messages.TradeInfos

    @behaviour XtbClient.Message

    @type t :: %__MODULE__{
            orders: [String.t()]
          }

    @enforce_keys [:orders]
    @derive Jason.Encoder
    defstruct orders: []

    def new(orders) when is_list(orders) do
      %__MODULE__{
        orders: orders
      }
    end

    @impl XtbClient.Message
    def operation(%__MODULE__{}), do: "getTradeRecords"

    @impl XtbClient.Message
    def encode(%__MODULE__{} = data), do: data

    @impl XtbClient.Message
    def decode(data), do: TradeInfos.new(data)
  end

  alias XtbClient.Messages.TradeInfo

  @type t :: %__MODULE__{
          data: [TradeInfo.t()]
        }

  @enforce_keys [:data]
  @derive Jason.Encoder
  defstruct data: []

  def new(data) when is_list(data) do
    %__MODULE__{
      data: Enum.map(data, &TradeInfo.new(&1))
    }
  end

  def new(data) when is_map(data) do
    TradeInfo.new(data)
  end
end
