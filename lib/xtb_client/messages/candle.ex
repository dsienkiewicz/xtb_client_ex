defmodule XtbClient.Messages.Candle do
  @moduledoc """
  Info representing aggregated price & volume values for candle.

  Default interval for one candle is one minute.

  ## Parameters
  - `open` open price in base currency,
  - `high` highest value in the given period in base currency,
  - `low` lowest value in the given period in base currency,
  - `close` close price in base currency,
  - `vol` volume in lots,
  - `ctm` candle start time in CET time zone (Central European Time),
  - `ctm_string` string representation of the `ctm` field,
  - `quote_id` source of price, see `XtbClient.Messages.QuoteId`,
  - `symbol` symbol name.
  """

  alias XtbClient.Messages.QuoteId

  @type t :: %__MODULE__{
          open: float(),
          high: float(),
          low: float(),
          close: float(),
          vol: float(),
          ctm: DateTime.t(),
          ctm_string: String.t(),
          quote_id: QuoteId.t(),
          symbol: String.t()
        }

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

  def new(
        %{
          "vol" => vol,
          "ctm" => ctm_value,
          "ctmString" => ctm_string
        } = args
      )
      when is_number(vol) and is_number(ctm_value) do
    value = args |> Map.drop(["vol", "ctm", "ctmString"]) |> new()

    %{
      value
      | vol: vol,
        ctm: DateTime.from_unix!(ctm_value, :millisecond),
        ctm_string: ctm_string || ""
    }
  end

  def new(%{"symbol" => symbol} = args) do
    value = args |> Map.drop(["symbol"]) |> new()

    %{
      value
      | symbol: symbol || ""
    }
  end

  def new(%{"quoteId" => quote_id} = args) when is_integer(quote_id) do
    value = args |> Map.drop(["quoteId"]) |> new()

    %{
      value
      | quote_id: QuoteId.parse(quote_id)
    }
  end

  def new(%{
        "open" => open,
        "high" => high,
        "low" => low,
        "close" => close
      })
      when is_number(open) and is_number(high) and is_number(low) and is_number(close) do
    %__MODULE__{
      open: open,
      high: high,
      low: low,
      close: close,
      vol: 0.0,
      ctm: nil,
      ctm_string: nil,
      quote_id: nil,
      symbol: nil
    }
  end

  def new(
        %{
          "open" => open,
          "high" => high,
          "low" => low,
          "close" => close
        } = args,
        digits
      )
      when is_number(open) and is_number(high) and is_number(low) and is_number(close) and
             is_number(digits) do
    args
    |> Map.merge(%{
      "open" => to_base_currency(open, digits),
      "high" => to_base_currency(open + high, digits),
      "low" => to_base_currency(open + low, digits),
      "close" => to_base_currency(open + close, digits)
    })
    |> new()
  end

  defp to_base_currency(value, digits) do
    value / :math.pow(10, digits)
  end
end
