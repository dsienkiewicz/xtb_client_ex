defmodule XtbClient.Messages.SymbolInfos do
  alias XtbClient.Messages.{SymbolInfo}

  @moduledoc """
  Represents a result of query for list of `XtbClient.Messages.SymbolInfo`s.
  """

  @type t :: %__MODULE__{
          data: [SymbolInfo.t()]
        }

  @enforce_keys [:data]
  defstruct data: []

  def new(data) when is_list(data) do
    %__MODULE__{
      data:
        data
        |> Enum.map(&SymbolInfo.new(&1))
    }
  end

  def match(method, data) when method in ["getAllSymbols"] do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
