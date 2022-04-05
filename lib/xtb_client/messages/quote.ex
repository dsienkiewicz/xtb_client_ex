defmodule XtbClient.Messages.Quote do
  alias XtbClient.Messages.Day

  @moduledoc """
  Info about quote for given day.
  
  Parameters:
  - `day` day of week,
  - `from` start time in `Time` CET / CEST time zone (see Daylight Saving Time, DST),
  - `to` end time in `Time` CET / CEST time zone (see Daylight Saving Time, DST).
  """

  @type t :: %__MODULE__{
          day: Day.t(),
          from: Time.t(),
          to: Time.t()
        }

  @enforce_keys [:day, :from, :to]

  @derive Jason.Encoder
  defstruct day: nil,
            from: nil,
            to: nil

  def new(%{
        "day" => day_value,
        "fromT" => from_value,
        "toT" => to_value
      })
      when is_integer(day_value) and is_integer(from_value) and is_integer(to_value) do
    %__MODULE__{
      day: Day.parse(day_value),
      from: Time.from_seconds_after_midnight(div(from_value, 1_000)),
      to: Time.from_seconds_after_midnight(div(to_value, 1_000))
    }
  end
end
