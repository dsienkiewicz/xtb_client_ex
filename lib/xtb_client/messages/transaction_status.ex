defmodule XtbClient.Messages.TransactionStatus do
  @moduledoc """
  Atoms representing transaction statuses.
  """

  @type t :: :error | :pending | :accepted | :rejected
  @type status_code :: 0 | 1 | 3 | 4

  @doc """
  Parse integer value as valid atom for transaction status.
  """
  @spec parse(status_code()) :: t()
  def parse(value) when value in [0, 1, 3, 4] do
    parse_status(value)
  end

  defp parse_status(value) do
    case value do
      0 -> :error
      1 -> :pending
      3 -> :accepted
      4 -> :rejected
    end
  end
end
