defmodule XtbClient.Messages.NewsInfos do
  @moduledoc """
  Query result for list of `XtbClient.Messages.NewsInfo`s.

  ## Parameters
  - `data` array or results.

  ## Handled Api methods
  - `getNews`
  """

  alias XtbClient.Messages.NewsInfo

  @type t :: %__MODULE__{
          data: [XtbClient.Messages.NewsInfo.t()]
        }

  @enforce_keys [:data]
  @derive Jason.Encoder
  defstruct data: []

  def new(data) when is_list(data) do
    %__MODULE__{
      data:
        data
        |> Enum.map(&NewsInfo.new(&1))
    }
  end

  def new(data) when is_map(data) do
    %__MODULE__{
      data: [NewsInfo.new(data)]
    }
  end
end
