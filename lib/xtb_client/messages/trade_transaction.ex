defmodule XtbClient.Messages.TradeTransaction do
  defmodule Command do
    alias XtbClient.Messages.{Operation, TradeType}

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

  @enforce_keys [:order]

  defstruct order: 0

  def new(%{"order" => order}) when is_integer(order) do
    %__MODULE__{
      order: order
    }
  end

  def match(%{"order" => _} = data) when map_size(data) == 1 do
    {:ok, __MODULE__.new(data)}
  end

  def match(_data) do
    {:no_match}
  end
end
