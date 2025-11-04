defmodule XtbClient.Messages.StepRules do
  @moduledoc """
  Query result for list of `XtbClient.Messages.StepRule`s.

  ## Parameters
  - `data` array or results.

  ## Handled Api methods
  - `getStepRules`
  """

  alias XtbClient.Messages.StepRule

  defmodule Query do
    @moduledoc """
    Returns a list of step rules for DMAs.
    """
    alias XtbClient.Messages.StepRules

    @behaviour XtbClient.Message

    @type t :: %__MODULE__{}

    @enforce_keys []
    @derive Jason.Encoder
    defstruct []

    def new do
      %__MODULE__{}
    end

    @impl XtbClient.Message
    def operation(%__MODULE__{}), do: "getStepRules"

    @impl XtbClient.Message
    def encode(%__MODULE__{} = data), do: data

    @impl XtbClient.Message
    def decode(data), do: StepRules.new(data)
  end

  @type t :: %__MODULE__{
          data: [StepRule.t()]
        }

  @enforce_keys [:data]
  @derive Jason.Encoder
  defstruct data: []

  def new(data)
      when is_list(data) do
    %__MODULE__{
      data: Enum.map(data, &StepRule.new(&1))
    }
  end
end
