defmodule XtbClient.Messages.TradeType do
  def format(type) when is_atom(type) do
    format_type(type)
  end

  defp format_type(type) do
    case type do
      :open -> 0
      :pending -> 1
      :close -> 2
      :modify -> 3
      :delete -> 4
    end
  end
end
