defmodule XtbClient.Messages.NewsInfos do
  @moduledoc """
  Query result for list of `XtbClient.Messages.NewsInfo`s.

  ## Parameters
  - `data` array or results.

  ## Handled Api methods
  - `getNews`
  """

  defmodule Query do
    @moduledoc """
    Returns news from trading server which were sent within specified period of time.

    **Please note that this function can be usually replaced by its streaming equivalent `subscribe_get_news/1` which is the preferred way of retrieving news data.**
    """
    alias XtbClient.Messages.DateRange
    alias XtbClient.Messages.NewsInfos

    @behaviour XtbClient.Message

    @type t :: %__MODULE__{date_range: DateRange.t()}

    @enforce_keys [:date_range]
    @derive Jason.Encoder
    defstruct date_range: nil

    def new(%DateRange{} = date_range) do
      %__MODULE__{date_range: date_range}
    end

    @impl XtbClient.Message
    def operation(%__MODULE__{}), do: "getNews"

    @impl XtbClient.Message
    def encode(%__MODULE__{} = data), do: data.date_range

    @impl XtbClient.Message
    def decode(data), do: NewsInfos.new(data)
  end

  alias XtbClient.Messages.NewsInfo

  @type t :: %__MODULE__{
          data: [XtbClient.Messages.NewsInfo.t()]
        }

  @enforce_keys [:data]
  @derive Jason.Encoder
  defstruct data: []

  def new(data) when is_list(data) do
    %__MODULE__{
      data: Enum.map(data, &NewsInfo.new(&1))
    }
  end

  def new(data) when is_map(data) do
    %__MODULE__{
      data: [NewsInfo.new(data)]
    }
  end
end
