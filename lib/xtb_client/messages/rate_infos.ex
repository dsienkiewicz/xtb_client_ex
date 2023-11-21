defmodule XtbClient.Messages.RateInfos do
  @moduledoc """
  Query result for list of `XtbClient.Messages.Candle`s.

  ## Parameters
  - `digits` number of decimal places,
  - `data` array of results.

  ## Handled Api methods
  - `getChartLastRequest`
  - `getChartRangeRequest`
  """

  alias XtbClient.Messages.Candle

  @type t :: %__MODULE__{
          digits: integer(),
          data: [Candle.t()]
        }

  @enforce_keys [:digits, :data]
  @derive Jason.Encoder
  defstruct digits: 0,
            data: []

  def new(%{
        "digits" => digits,
        "rateInfos" => rate_infos
      })
      when is_integer(digits) and
             is_list(rate_infos) do
    %__MODULE__{
      digits: digits,
      data: Enum.map(rate_infos, &Candle.new(&1, digits))
    }
  end
end
