defmodule XtbClient.Messages.MarginTrade do
  @enforce_keys [:margin]

  @derive Jason.Encoder
  defstruct margin: 0.0

  def new(%{"margin" => margin}) when is_number(margin) do
    %__MODULE__{
      margin: margin
    }
  end
end
