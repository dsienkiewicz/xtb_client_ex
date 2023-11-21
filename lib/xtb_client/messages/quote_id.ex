defmodule XtbClient.Messages.QuoteId do
  @moduledoc """
  Atoms representing quote ID.
  """

  @type t :: :fixed | :float | :depth | :cross | :five | :six
  @type quote_code :: 1 | 2 | 3 | 4 | 5 | 6

  @doc """
  Parse an integer number as valid atom for quote ID.
  """
  @spec parse(value :: quote_code()) :: t()
  def parse(value) when is_integer(value) and value in [1, 2, 3, 4, 5, 6] do
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
