defmodule XtbClient.Messages.RateInfos do
  alias XtbClient.Messages.{RateInfo}
  @enforce_keys [:digits, :data]

  defstruct digits: 0,
            data: []

  def new(%{
        "digits" => digits,
        "rateInfos" => rate_infos
      })
      when is_number(digits) and
             is_list(rate_infos) do
    %__MODULE__{
      digits: digits,
      data:
        rate_infos
        |> Enum.map(&RateInfo.new(&1, digits))
    }
  end

  def match(method, data) when method in ["getChartLastRequest", "getChartRangeRequest"] do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
