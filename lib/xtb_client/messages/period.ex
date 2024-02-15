defmodule XtbClient.Messages.Period do
  @moduledoc """
  Specifies time interval - counted in multiples of minute.
  """

  @type t :: :m1 | :m5 | :m15 | :m30 | :h1 | :h4 | :d1 | :w1 | :mn1
  @type minute_period :: 1 | 5 | 15 | 30 | 60 | 240 | 1440 | 10_080 | 43_200

  @map [
    m1: 1,
    m5: 5,
    m15: 15,
    m30: 30,
    h1: 60,
    h4: 240,
    d1: 1440,
    w1: 10_080,
    mn1: 43_200
  ]

  defguard is_period(atom)
           when is_atom(atom) and atom in [:m1, :m5, :m15, :m30, :h1, :h4, :d1, :w1, :mn1]

  @doc """
  Parses value given as number of minutes to `Period` atom type.
  """
  @spec parse(value :: minute_period()) :: t()
  for {period, minutes} <- @map do
    def parse(unquote(minutes)), do: unquote(period)
  end

  @doc """
  Formats period given as `Period` to number of minutes.
  """
  @spec format(period :: t()) :: minute_period()
  for {period, minutes} <- @map do
    def format(unquote(period)), do: unquote(minutes)
  end
end
