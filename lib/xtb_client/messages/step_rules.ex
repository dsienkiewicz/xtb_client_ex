defmodule XtbClient.Messages.StepRules do
  alias XtbClient.Messages.StepRule

  @moduledoc """
  Query result for list of `XtbClient.Messages.StepRule`s.
  
  ## Parameters
  - `data` array or results.
  
  ## Handled Api methods
  - `getStepRules`
  """

  @type t :: %__MODULE__{
          data: [StepRule.t()]
        }

  @enforce_keys [:data]

  defstruct data: []

  def new(data)
      when is_list(data) do
    %__MODULE__{
      data:
        data
        |> Enum.map(&StepRule.new(&1))
    }
  end

  def match(method, data) when method in ["getStepRules"] do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
