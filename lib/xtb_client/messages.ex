defmodule XtbClient.Messages do
  alias XtbClient.Messages.Period

  def format_period(period) do
    Period.format(period)
  end

  def parse_period(value) do
    Period.parse(value)
  end
end
