defmodule XtbClient.Messages.MarginMode do
  @type t :: :forex | :cfd_leveraged | :cfd | :hundred_and_four
  @type margin_number :: 101 | 102 | 103 | 104

  @spec parse(margin_number()) :: t()
  def parse(value) when is_number(value) and value > 0 do
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
