defmodule XtbClient.Messages.MarginMode do
  @moduledoc """
  Atoms representing margin mode.
  """

  @type t :: :forex | :cfd_leveraged | :cfd | :hundred_and_four
  @type margin_code :: 101 | 102 | 103 | 104

  @doc """
  Parse an integer value as a valid atom for margin mode.
  """
  @spec parse(value :: margin_code()) :: t()
  def parse(value) when is_number(value) and value in [101, 102, 103, 104] do
    parse_margin_mode(value)
  end

  defp parse_margin_mode(value) do
    case value do
      101 -> :forex
      102 -> :cfd_leveraged
      103 -> :cfd
      104 -> :hundred_and_four
    end
  end
end
