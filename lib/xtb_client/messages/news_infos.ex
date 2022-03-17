defmodule XtbClient.Messages.NewsInfos do
  alias XtbClient.Messages.NewsInfo

  @enforce_keys [:data]
  defstruct data: []

  def new(data) when is_list(data) do
    %__MODULE__{
      data:
        data
        |> Enum.map(&NewsInfo.new(&1))
    }
  end

  def new(data) when is_map(data) do
    NewsInfo.new(data)
  end

  def match(method, data) when method in ["getNews"] do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
