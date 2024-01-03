defmodule XtbClient.Messages.MarginMode do
  @moduledoc """
  Atoms representing margin mode.
  """

  @type t :: :forex | :cfd_leveraged | :cfd | :hundred_and_four
  @type margin_code :: 101 | 102 | 103 | 104

  @map [
    forex: 101,
    cfd_leveraged: 102,
    cfd: 103,
    hundred_and_four: 104
  ]

  @doc """
  Parse an integer value as a valid atom for margin mode.
  """
  @spec parse(value :: margin_code()) :: t()
  for {mode, value} <- @map do
    def parse(unquote(value)), do: unquote(mode)
  end
end
