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

  @doc """
  Parse an integer value as a valid atom representing day of week.
  """
  @spec parse(day_code()) :: t()
  def parse(value) when is_integer(value) and value in 1..7 do
    parse_day(value)
  end

  defp parse_day(value) do
    case value do
      1 -> :monday
      2 -> :tuesday
      3 -> :wednesday
      4 -> :thursday
      5 -> :friday
      6 -> :saturday
      7 -> :sunday
    end
  end
end
