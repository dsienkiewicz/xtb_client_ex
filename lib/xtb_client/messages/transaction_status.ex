defmodule XtbClient.Messages.TransactionStatus do
  def parse(value) when is_number(value) do
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
