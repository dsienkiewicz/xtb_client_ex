defmodule XtbClient.Messages.SymbolInfos do
  @moduledoc """
  Query result for list of `XtbClient.Messages.SymbolInfo`s.

  ## Parameters
  - `data` array or results.

  ## Handled Api methods
  - `getAllSymbols`
  """

  alias XtbClient.Messages.SymbolInfo

  @type t :: %__MODULE__{
          data: [SymbolInfo.t()]
        }

  @enforce_keys [:data]
  @derive Jason.Encoder
  defstruct data: []

  def new(data) when is_list(data) do
    %__MODULE__{
      data: Enum.map(data, &SymbolInfo.new(&1))
    }
  end
end
