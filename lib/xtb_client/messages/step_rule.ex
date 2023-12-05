defmodule XtbClient.Messages.StepRule do
  @moduledoc """
  Info about step rule definition.

  ## Parameters
  - `id` step rule ID,
  - `name` step rule name,
  - `steps` array of `XtbClient.Messages.Step`s.
  """

  alias XtbClient.Messages.Step

  @type t :: %__MODULE__{
          id: integer(),
          name: String.t(),
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
      when is_number(id) and is_list(steps) do
    %__MODULE__{
      id: id,
      name: name || "",
      steps: Enum.map(steps, &Step.new(&1))
    }
  end
end
