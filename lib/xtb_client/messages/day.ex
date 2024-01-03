defmodule XtbClient.Messages.Day do
  @moduledoc """
  Atoms representing day of week.
  """

  @type t ::
          :monday
          | :tuesday
          | :wednesday
          | :thursday
          | :friday
          | :saturday
          | :sunday

  @type day_code :: 1..7

  @map [
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6,
    sunday: 7
  ]

  @doc """
  Parse an integer value as a valid atom representing day of week.
  """
  @spec parse(value :: day_code()) :: t()
  for {day, value} <- @map do
    def parse(unquote(value)), do: unquote(day)
  end
end
