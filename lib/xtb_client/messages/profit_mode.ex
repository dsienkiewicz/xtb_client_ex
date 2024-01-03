defmodule XtbClient.Messages.ProfitMode do
  @moduledoc """
  Atoms representing profit mode.
  """

  @type t :: :forex | :cfd
  @type profit_code :: 5 | 6

  @map [
    forex: 5,
    cfd: 6
  ]

  @doc """
  Parse an integer value to valid atom of profit mode.
  """
  @spec parse(value :: profit_code()) :: t()
  for {mode, value} <- @map do
    def parse(unquote(value)), do: unquote(mode)
  end
end
