defmodule XtbClient.Messages.Candles do
  defmodule SubscribeCandlesCommand do
    @moduledoc """
    Command for subscribing to API chart candles.
    The interval of every candle is 1 minute. A new candle arrives every minute.

    ## Parameters
    - `symbol` - symbol name.
    """
    alias XtbClient.Messages.Candle

    @behaviour XtbClient.StreamingMessage

    @type t :: %__MODULE__{
            symbol: String.t(),
            metadata: map() | nil
          }

    @enforce_keys [:symbol]
    @derive {Jason.Encoder, only: [:symbol]}
    defstruct symbol: "", metadata: nil

    def new(symbol, metadata \\ nil) when is_binary(symbol) do
      %__MODULE__{symbol: symbol, metadata: metadata}
    end

    @impl XtbClient.StreamingMessage
    def operation(%__MODULE__{}), do: "getCandles"

    @impl XtbClient.StreamingMessage
    def response_path(%__MODULE__{}), do: "candle"

    @impl XtbClient.StreamingMessage
    def encode(%__MODULE__{} = data), do: data

    @impl XtbClient.StreamingMessage
    def decode(data), do: Candle.new(data)

    @impl XtbClient.StreamingMessage
    def hash(%__MODULE__{symbol: symbol}), do: "candle:#{symbol}"

    @impl XtbClient.StreamingMessage
    def fetch_metadata(%__MODULE__{} = data), do: data.metadata
  end

  defmodule UnsubscribeCandlesCommand do
    @moduledoc """
    Command for unsubscribing from API chart candles.

    ## Parameters
    - `symbol` - symbol name.
    """
    @behaviour XtbClient.StreamingMessage

    @type t :: %__MODULE__{
            symbol: String.t()
          }

    @enforce_keys [:symbol]
    @derive Jason.Encoder
    defstruct symbol: ""

    def new(symbol) when is_binary(symbol) do
      %__MODULE__{symbol: symbol}
    end

    @impl XtbClient.StreamingMessage
    def operation(%__MODULE__{}), do: "stopCandles"

    @impl XtbClient.StreamingMessage
    def response_path(%__MODULE__{}), do: "candle"

    @impl XtbClient.StreamingMessage
    def encode(%__MODULE__{} = data), do: data

    @impl XtbClient.StreamingMessage
    def decode(data), do: data

    @impl XtbClient.StreamingMessage
    def hash(%__MODULE__{symbol: symbol}), do: "candle:#{symbol}"

    @impl XtbClient.StreamingMessage
    def fetch_metadata(%__MODULE__{}), do: nil
  end
end
