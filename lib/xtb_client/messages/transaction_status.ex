defmodule XtbClient.Messages.TransactionStatus do
  @moduledoc """
  Atoms representing transaction statuses.
  """

  @type t :: :error | :pending | :accepted | :rejected
  @type status_code :: 0 | 1 | 3 | 4

  @map [
    error: 0,
    pending: 1,
    accepted: 3,
    rejected: 4
  ]

  @doc """
  Parse integer value as valid atom for transaction status.
  """
  @spec parse(value :: status_code()) :: t()
  for {status, value} <- @map do
    def parse(unquote(value)), do: unquote(status)
  end
end
