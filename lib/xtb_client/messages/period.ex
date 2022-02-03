defmodule XtbClient.Messages.Period do
  def format(period) when is_atom(period) do
    format_perod(period)
  end

  defp format_perod(period) do
    case period do
      :m1 -> 1
      :m5 -> 5
      :m15 -> 15
      :m30 -> 30
      :h1 -> 60
      :h4 -> 240
      :d1 -> 1440
      :w1 -> 10080
      :mn1 -> 43200
    end
  end

  def parse(value) when is_number(value) and value > 0 do
    parse_period(value)
  end

  defp parse_period(value) do
    case value do
      1 -> :m1
      5 -> :m5
      15 -> :m15
      30 -> :m30
      60 -> :h1
      240 -> :h4
      1440 -> :d1
      10080 -> :w1
      43200 -> :mn1
    end
  end
end
