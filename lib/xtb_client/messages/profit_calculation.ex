defmodule XtbClient.Messages.ProfitCalculation do
  defmodule Query do
    alias XtbClient.Messages.{Operation}

    @enforce_keys [:closePrice, :cmd, :openPrice, :symbol, :volume]

    @derive Jason.Encoder
    defstruct closePrice: 0.0,
              cmd: nil,
              openPrice: 0.0,
              symbol: "",
              volume: 0.0

    def new(%{
          close_price: close_price,
          operation: operation,
          open_price: open_price,
          symbol: symbol,
          volume: volume
        })
        when is_number(close_price) and is_atom(operation) and
               is_number(open_price) and is_binary(symbol) and is_number(volume) do
      %__MODULE__{
        closePrice: close_price,
        cmd: Operation.format(operation),
        openPrice: open_price,
        symbol: symbol,
        volume: volume
      }
    end
  end

  @enforce_keys [:profit]

  @derive Jason.Encoder
  defstruct profit: 0.0

  def new(%{"profit" => profit}) when is_number(profit) do
    %__MODULE__{
      profit: profit
    }
  end
end
