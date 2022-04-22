defmodule XtbClient.Messages.CalendarInfos do
  alias XtbClient.Messages.{CalendarInfo}

  @moduledoc """
  Query result for list of `XtbClient.Messages.CalendarInfo`s.
  
  ## Parameters
  - `data` array or results.
  
  ## Handled Api methods
  - `getCalendar`
  """

  @type t :: %__MODULE__{
          data: [CalendarInfo.t()]
        }

  @enforce_keys [:data]
  defstruct data: []

  def new(data) when is_list(data) do
    %__MODULE__{
      data:
        data
        |> Enum.map(&CalendarInfo.new(&1))
    }
  end

  def match(method, data) when method in ["getCalendar"] do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
