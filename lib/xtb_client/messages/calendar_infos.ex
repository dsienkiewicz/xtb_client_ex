defmodule XtbClient.Messages.CalendarInfos do
  @moduledoc """
  Query result for list of `XtbClient.Messages.CalendarInfo`s.

  ## Parameters
  - `data` array or results.

  ## Handled Api methods
  - `getCalendar`
  """

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
