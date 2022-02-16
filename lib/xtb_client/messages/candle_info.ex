defmodule XtbClient.Messages.CandleInfo do
  @enforce_keys [
    :open,
    :high,
    :low,
    :close,
    :vol,
    :ctm,
    :ctm_string,
    :quote_id,
    :symbol
  ]

  @derive Jason.Encoder
  defstruct open: 0.0,
            high: 0.0,
            low: 0.0,
            close: 0.0,
            vol: 0.0,
            ctm: nil,
            ctm_string: "",
            quote_id: nil,
            symbol: ""

  def new(%{
        "open" => open,
        "high" => high,
        "low" => low,
        "close" => close,
        "vol" => vol,
        "ctm" => ctm_value,
        "ctmString" => ctm_string,
        "quoteId" => quote_id,
        "symbol" => symbol
      })
      when is_number(open) and is_number(high) and is_number(low) and is_number(close) and
             is_number(vol) and not is_nil(ctm_value) and is_binary(ctm_string) and
             is_number(quote_id) and
             is_binary(symbol) do
    %__MODULE__{
      open: open,
      high: high,
      low: low,
      close: close,
      vol: vol,
      ctm: DateTime.from_unix!(ctm_value, :millisecond),
      ctm_string: ctm_string,
      quote_id: quote_id,
      symbol: symbol
    }
  end
end
