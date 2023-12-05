defmodule XtbClient.Messages.ProfitMode do
  @moduledoc """
  Atoms representing profit mode.
  """

  @type t :: :forex | :cfd
  @type profit_code :: 5 | 6

  @doc """
  Parse an integer value to valid atom of profit mode.
  """
  @spec parse(value :: profit_code()) :: t()
  def parse(value) when is_number(value) and value in [5, 6] do
    parse_profit_mode(value)
  end

  defp parse_profit_mode(value) do
    case value do
      5 -> :forex
      6 -> :cfd
    end
  end
end
