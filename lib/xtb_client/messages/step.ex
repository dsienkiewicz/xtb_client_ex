defmodule XtbClient.Messages.Step do
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
