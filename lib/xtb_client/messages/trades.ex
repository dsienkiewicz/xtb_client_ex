defmodule XtbClient.Messages.Trades do
  defmodule Query do
    @enforce_keys [:openedOnly]

    @derive Jason.Encoder
    defstruct openedOnly: nil

    def new(opened_only) when is_boolean(opened_only) do
      %__MODULE__{
        openedOnly: opened_only
      }
    end
  end
end
