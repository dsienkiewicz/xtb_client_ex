defmodule XtbClient.Messages.MarginTrade do
  @moduledoc """
  Info about calculated margin in account currency.

  ## Properties
  - `margin` value of margin.

  ## Handled Api methods
  - `getMarginTrade`
  """

  @type t :: %__MODULE__{
          margin: float()
        }

  @enforce_keys [:margin]
  @derive Jason.Encoder
  defstruct margin: 0.0

  def new(%{"margin" => margin}) when is_number(margin) do
    %__MODULE__{
      margin: margin
    }
  end
end
