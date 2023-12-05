defmodule XtbClient.Messages.Period do
  @moduledoc """
  Specifies time interval - counted in multiples of minute.
  """

  @type t :: :m1 | :m5 | :m15 | :m30 | :h1 | :h4 | :d1 | :w1 | :mn1
  @type minute_period :: 1 | 5 | 15 | 30 | 60 | 240 | 1440 | 10_080 | 43_200

  @doc """
  Formats period given as `Period` to number of minutes.
  """
  @spec format(period :: t()) :: minute_period()
  def format(period) when is_atom(period) do
    format_period(period)
  end

  defp format_period(period) do
    case period do
      :m1 -> 1
      :m5 -> 5
      :m15 -> 15
      :m30 -> 30
      :h1 -> 60
      :h4 -> 240
      :d1 -> 1440
      :w1 -> 10_080
      :mn1 -> 43_200
    end
  end

  @doc """
  Parses value given as number of minutes to `Period` atom type.
  """
  @spec parse(value :: minute_period()) :: t()
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
      10_080 -> :w1
      43_200 -> :mn1
    end
  end
end
