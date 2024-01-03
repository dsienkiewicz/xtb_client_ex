defmodule XtbClient.Messages.QuoteId do
  @moduledoc """
  Atoms representing quote ID.
  """

  @type t :: :fixed | :float | :depth | :cross | :five | :six
  @type quote_code :: 1..6

  @map [
    fixed: 1,
    float: 2,
    depth: 3,
    cross: 4,
    five: 5,
    six: 6
  ]

  @doc """
  Parse an integer number as valid atom for quote ID.
  """
  @spec parse(value :: quote_code()) :: t()
  for {code, value} <- @map do
    def parse(unquote(value)), do: unquote(code)
  end
end
