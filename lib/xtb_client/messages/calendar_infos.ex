defmodule XtbClient.Messages.CalendarInfos do
  alias XtbClient.Messages.{CalendarInfo}

  @enforce_keys [:data]
  defstruct data: []

  def new(data) when is_list(data) do
    %__MODULE__{
      data:
        data
        |> Enum.map(&CalendarInfo.new(&1))
    }
  end

  def match([%{"country" => _, "current" => _} | _] = data) do
    {:ok, __MODULE__.new(data)}
  end

  def match(_data) do
    {:no_match}
  end
end
