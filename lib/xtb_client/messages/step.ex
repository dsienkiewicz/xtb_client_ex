defmodule XtbClient.Messages.Step do
  @moduledoc """
  Info about one step rule.
  
  ## Parameters
  - `from_value` lower border of the volume range,
  - `step` 	lotStep value in the given volume range.
  """

  @type t :: %__MODULE__{
          from_value: float(),
          step: float()
        }

  @enforce_keys [:from_value, :step]

  @derive Jason.Encoder
  defstruct from_value: 0.0,
            step: 0.0

  def new(%{
        "fromValue" => from,
        "step" => step
      })
      when is_number(from) and is_number(step) do
    %__MODULE__{
      from_value: from,
      step: step
    }
  end
end
