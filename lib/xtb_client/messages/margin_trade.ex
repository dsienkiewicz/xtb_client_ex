defmodule XtbClient.Messages.MarginTrade do
  @moduledoc """
  Info about calculated margin in account currency.
  """

  @type t :: %__MODULE__{
          margin: number()
        }

  @enforce_keys [:margin]

  @derive Jason.Encoder
  defstruct margin: 0.0

  def new(%{"margin" => margin}) when is_number(margin) do
    %__MODULE__{
      margin: margin
    }
  end

  def match(method, data) when method in ["getMarginTrade"] do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
