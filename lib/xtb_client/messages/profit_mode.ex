defmodule XtbClient.Messages.ProfitMode do
  @type t :: :forex | :cfd
  @type proft_number :: 5 | 6

  @spec parse(proft_number()) :: t()
  def parse(value) when is_number(value) and value in [5, 6] do
    parse_profit_mode(value)
  end

  defp parse_profit_mode(value) do
    case value do
      5 -> :forex
      6 -> :cfd
    end
  end
end
