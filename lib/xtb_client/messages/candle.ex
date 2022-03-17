defmodule XtbClient.Messages.Candle do
  alias XtbClient.Messages.QuoteId

  @enforce_keys [:close, :ctm, :ctm_string, :high, :low, :open, :vol]

  @derive Jason.Encoder
  defstruct close: 0.0,
            ctm: nil,
            ctm_string: "",
            high: 0.0,
            low: 0.0,
            open: 0.0,
            quote_id: nil,
            symbol: "",
            vol: 0.0

  def new(%{
        "close" => close,
        "ctm" => ctm_value,
        "ctmString" => ctm_string,
        "high" => high,
        "low" => low,
        "open" => open,
        "quoteId" => quote_id,
        "symbol" => symbol,
        "vol" => vol
      })
      when is_number(close) and is_number(ctm_value) and is_binary(ctm_string) and
             is_number(high) and is_number(low) and is_number(open) and
             is_integer(quote_id) and is_binary(symbol) and
             is_number(vol) do
    %__MODULE__{
      ctm: DateTime.from_unix!(ctm_value, :millisecond),
      ctm_string: ctm_string,
      open: open,
      high: high,
      low: low,
      close: close,
      quote_id: QuoteId.parse(quote_id),
      symbol: symbol,
      vol: vol
    }
  end
end
