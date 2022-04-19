defmodule XtbClient.Messages.Trades do
  defmodule Query do
    @moduledoc """
    Info about the query for trades.
    
    ## Parameters
    - `openedOnly` if true then only opened trades will be returned.
    """

    @type t :: %__MODULE__{
            openedOnly: boolean()
          }

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
