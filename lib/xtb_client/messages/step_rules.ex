defmodule XtbClient.Messages.StepRules do
  alias XtbClient.Messages.StepRule
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

  def match([%{"id" => _, "name" => _, "steps" => _} | _] = data) do
    {:ok, __MODULE__.new(data)}
  end

  def match(_data) do
    {:no_match}
  end
end
