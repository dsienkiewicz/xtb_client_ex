defmodule XtbClient.Messages.StepRule do
  alias XtbClient.Messages.Step

  @type t :: %__MODULE__{
          id: integer(),
          name: binary(),
          steps: [Step.t()]
        }

  @enforce_keys [:id, :name, :steps]

  @derive Jason.Encoder
  defstruct id: 0,
            name: "",
            steps: []

  def new(%{
        "id" => id,
        "name" => name,
        "steps" => steps
      })
      when is_number(id) and is_binary(name) and is_list(steps) do
    %__MODULE__{
      id: id,
      name: name,
      steps: Enum.map(steps, &Step.new(&1))
    }
  end
end
