defmodule XtbClient.Messages.RateInfo do
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
