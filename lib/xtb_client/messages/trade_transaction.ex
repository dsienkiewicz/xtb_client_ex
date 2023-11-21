defmodule XtbClient.Messages.TradeTransaction do
  @moduledoc """
  Info about realized trade transaction.

  ## Parameters
  - `order` holds info about order number, needed later for verification about order status.

  ## Handled Api methods
  - `tradeTransaction`
  """

  defmodule Command do
    @moduledoc """
    Info about command to trade the transaction.

    ## Parameters
    - `cmd` operation code, see `XtbClient.Messages.Operation`,
    - `customComment` the value the customer may provide in order to retrieve it later,
    - `expiration` pending order expiration time,
    - `offset` trailing offset,
    - `order` `0` or position number for closing/modifications,
    - `price` trade price,
    - `sl` stop loss,
    - `tp` take profit,
    - `symbol` trade symbol,
    - `type` trade transaction type, see `XtbClient.Messages.TradeType`,
    - `volume` trade volume.
    """

    alias XtbClient.Messages.{Operation, TradeType}

    @type t :: %__MODULE__{
            cmd: integer(),
            customComment: String.t(),
            expiration: integer(),
            offset: integer(),
            order: integer(),
            price: float(),
            sl: float(),
            tp: float(),
            symbol: String.t(),
            type: integer(),
            volume: float()
          }

    @derive Jason.Encoder
    defstruct cmd: nil,
              customComment: "",
              expiration: 0,
              offset: 0,
              order: 0,
              price: 0.0,
              sl: 0.0,
              tp: 0.0,
              symbol: "",
              type: nil,
              volume: 0.0

    def new(%{} = params) do
      params
      |> Enum.reduce(%__MODULE__{}, fn {key, value}, acc ->
        apply(__MODULE__, key, [acc, value])
      end)
    end

    def operation(%__MODULE__{} = params, operation) when is_atom(operation) do
      %{params | cmd: Operation.format(operation)}
    end

    def custom_comment(%__MODULE__{} = params, comment) when is_binary(comment) do
      %{params | customComment: comment}
    end

    def expiration(%__MODULE__{} = params, %DateTime{} = expiration) do
      %{params | expiration: DateTime.to_unix(expiration, :millisecond)}
    end

    def offset(%__MODULE__{} = params, offset) when is_integer(offset) do
      %{params | offset: offset}
    end

    def order(%__MODULE__{} = params, order) when is_integer(order) and order > 0 do
      %{params | order: order}
    end

    def price(%__MODULE__{} = params, price) when is_number(price) do
      %{params | price: price}
    end

    def stop_loss(%__MODULE__{} = params, sl) when is_number(sl) do
      %{params | sl: sl}
    end

    def take_profit(%__MODULE__{} = params, tp) when is_number(tp) do
      %{params | tp: tp}
    end

    def symbol(%__MODULE__{} = params, symbol) when is_binary(symbol) do
      %{params | symbol: symbol}
    end

    def type(%__MODULE__{} = params, type) when is_atom(type) do
      %{params | type: TradeType.format(type)}
    end

    def volume(%__MODULE__{} = params, volume) when is_number(volume) do
      %{params | volume: volume}
    end
  end

  @type t :: %__MODULE__{
          order: integer()
        }

  @enforce_keys [:order]
  @derive Jason.Encoder
  defstruct order: 0

  def new(%{"order" => order}) when is_integer(order) do
    %__MODULE__{
      order: order
    }
  end
end
