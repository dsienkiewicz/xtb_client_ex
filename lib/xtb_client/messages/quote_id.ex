defmodule XtbClient.Messages.QuoteId do
  def parse(value) when is_integer(value) and value > 0 do
    parse_quote_id(value)
  end

  defp parse_quote_id(value) do
    case value do
      1 -> :fixed
      2 -> :float
      3 -> :depth
      4 -> :cross
      5 -> :five
      6 -> :six
    end
  end
end
