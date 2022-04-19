defmodule XtbClient.Messages.Period do
  @moduledoc """
  Specifies time interval - counted in multiples of minute.
  """

  @type t :: :m1 | :m5 | :m15 | :m30 | :h1 | :h4 | :d1 | :w1 | :mn1
  @type minute_period :: 1 | 5 | 15 | 30 | 60 | 240 | 1440 | 10080 | 43200

  @doc """
  Formats period given as `Period` to number of minutes.
  """
  @spec format(t()) :: minute_period()
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

  @doc """
  Parses value given as number of minutes to `Period` atom type.
  """
  @spec parse(minute_period()) :: t()
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
