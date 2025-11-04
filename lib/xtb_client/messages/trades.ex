defmodule XtbClient.Messages.Trades do
  defmodule TradesQuery do
    @moduledoc """
    Returns array of user's trades.

    **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_trades/1` which is the preferred way of retrieving trades data.**

    ## Parameters
    - `openedOnly` - if true then only opened trades will be returned.
    """
    alias XtbClient.Messages.TradeInfos

    @behaviour XtbClient.Message

    @type t :: %__MODULE__{
            openedOnly: boolean()
          }

    @enforce_keys [:openedOnly]
    @derive Jason.Encoder
    defstruct openedOnly: nil

    def new(opened_only) when is_boolean(opened_only) do
      %__MODULE__{
        openedOnly: opened_only
      }
    end

    @impl XtbClient.Message
    def operation(%__MODULE__{}), do: "getTrades"

    @impl XtbClient.Message
    def encode(%__MODULE__{} = data), do: data

    @impl XtbClient.Message
    def decode(data), do: TradeInfos.new(data)
  end

  defmodule TradesHistoryQuery do
    @moduledoc """
    Returns array of user's trades which were closed within specified period of time.

    ## Parameters
    - `date_range` - date range for trades history.
    """
    alias XtbClient.Messages.DateRange
    alias XtbClient.Messages.TradeInfos

    @behaviour XtbClient.Message

    @type t :: %__MODULE__{
            date_range: DateRange.t()
          }

    @enforce_keys [:date_range]
    @derive Jason.Encoder
    defstruct date_range: nil

    def new(%DateRange{} = date_range) do
      %__MODULE__{
        date_range: date_range
      }
    end

    @impl XtbClient.Message
    def operation(%__MODULE__{}), do: "getTradesHistory"

    @impl XtbClient.Message
    def encode(%__MODULE__{} = data), do: data.date_range

    @impl XtbClient.Message
    def decode(data), do: TradeInfos.new(data)
  end
end
