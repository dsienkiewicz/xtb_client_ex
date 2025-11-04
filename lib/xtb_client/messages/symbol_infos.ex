defmodule XtbClient.Messages.SymbolInfos do
  @moduledoc """
  Query result for list of `XtbClient.Messages.SymbolInfo`s.

  ## Parameters
  - `data` array or results.

  ## Handled Api methods
  - `getAllSymbols`
  """

  defmodule Query do
    @moduledoc """
    Returns array of all symbols available for the user.
    """
    alias XtbClient.Messages.SymbolInfos

    @behaviour XtbClient.Message

    @type t :: %__MODULE__{}

    @enforce_keys []
    @derive Jason.Encoder
    defstruct []

    def new do
      %__MODULE__{}
    end

    @impl XtbClient.Message
    def operation(%__MODULE__{}), do: "getAllSymbols"

    @impl XtbClient.Message
    def encode(%__MODULE__{} = data), do: data

    @impl XtbClient.Message
    def decode(data), do: SymbolInfos.new(data)
  end

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
