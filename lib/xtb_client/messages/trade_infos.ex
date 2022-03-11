defmodule XtbClient.Messages.TradeInfos do
  defmodule Query do
    @enforce_keys [:orders]

    @derive Jason.Encoder
    defstruct orders: []

    def new(orders) when is_list(orders) do
      %__MODULE__{
        orders: orders
      }
    end
  end

  alias XtbClient.Messages.TradeInfo

  @enforce_keys [:data]
  defstruct data: []

  def new(data) when is_list(data) do
    %__MODULE__{
      data:
        data
        |> Enum.map(&TradeInfo.new(&1))
    }
  end

  def match(method, data) when method in ["getTradeRecords", "getTrades", "getTradesHistory"] do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
