defmodule XtbClient.Messages.StepRules do
  @moduledoc """
  Query result for list of `XtbClient.Messages.StepRule`s.

  ## Parameters
  - `data` array or results.

  ## Handled Api methods
  - `getStepRules`
  """

  alias XtbClient.Messages.StepRule

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
