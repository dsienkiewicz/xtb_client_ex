defmodule XtbClient.Messages.ProfitMode do
  def parse(value) when is_number(value) and value > 0 do
    parse_profit_mode(value)
  end

  defp parse_profit_mode(value) do
    case value do
      5 -> :forex
      6 -> :cfd
    end
  end
end
