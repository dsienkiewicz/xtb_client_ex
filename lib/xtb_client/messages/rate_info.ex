defmodule XtbClient.Messages.RateInfo do
  @moduledoc """
  Represents chart info candle, described by properties:
  - `close` value of close price,
  - `ctm` candle start time in CET / CEST time zone (see Daylight Saving Time, DST),
  - `ctm_string` string representation of the `ctm` field,
  - `high` highest value in the given period,
  - `low` lowest value in the given period,
  - `open` open price,
  - `vol` volume in lots.
  """

  @type t :: %__MODULE__{
          close: float(),
          ctm: DateTime.t(),
          ctm_string: binary(),
          high: float(),
          low: float(),
          open: float(),
          vol: float()
        }

  @enforce_keys [:close, :ctm, :ctm_string, :high, :low, :open, :vol]

  @derive Jason.Encoder
  defstruct close: 0.0,
            ctm: nil,
            ctm_string: "",
            high: 0.0,
            low: 0.0,
            open: 0.0,
            vol: 0.0

  def new(
        %{
          "close" => close,
          "ctm" => ctm_value,
          "ctmString" => ctm_string,
          "high" => high,
          "low" => low,
          "open" => open,
          "vol" => vol
        },
        digits
      )
      when is_number(close) and is_number(ctm_value) and is_binary(ctm_string) and
             is_number(high) and is_number(low) and is_number(open) and is_number(vol) and
             is_number(digits) do
    %__MODULE__{
      ctm: DateTime.from_unix!(ctm_value, :millisecond),
      ctm_string: ctm_string,
      open: to_base_currency(open, digits),
      high: to_base_currency(open + high, digits),
      low: to_base_currency(open + low, digits),
      close: to_base_currency(open + close, digits),
      vol: vol
    }
  end

  defp to_base_currency(value, digits) do
    value / :math.pow(10, digits)
  end
end
