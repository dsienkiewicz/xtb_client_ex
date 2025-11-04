defmodule XtbClient.Messages.CalendarInfos do
  @moduledoc """
  Query result for list of `XtbClient.Messages.CalendarInfo`s.

  ## Parameters
  - `data` array or results.

  ## Handled Api methods
  - `getCalendar`
  """

  defmodule Query do
    @moduledoc """
    Returns calendar with market events.
    """
    alias XtbClient.Messages.CalendarInfos

    @behaviour XtbClient.Message

    @type t :: %__MODULE__{}

    @enforce_keys []
    @derive Jason.Encoder
    defstruct []

    def new do
      %__MODULE__{}
    end

    @impl XtbClient.Message
    def operation(%__MODULE__{}), do: "getCalendar"

    @impl XtbClient.Message
    def encode(%__MODULE__{} = data), do: data

    @impl XtbClient.Message
    def decode(data), do: CalendarInfos.new(data)
  end

  alias XtbClient.Messages.CalendarInfo

  @type t :: %__MODULE__{
          data: [CalendarInfo.t()]
        }

  @enforce_keys [:data]
  @derive Jason.Encoder
  defstruct data: []

  def new(data) when is_list(data) do
    %__MODULE__{
      data: Enum.map(data, &CalendarInfo.new(&1))
    }
  end
end
