defmodule XtbClient.Messages.ProfitCalculation do
  defmodule Query do
    alias XtbClient.Messages.{Operation}

    @moduledoc """
    Info about query for calculation of profit.

    ## Parameters
    - `closePrice` theoretical close price of order,
    - `cmd` operation code, see `XtbClient.Messages.Operation`,
    - `openPrice` theoretical open price of order,
    - `symbol` symbol name,
    - `volume` volume in lots.
    """

    @type t :: %__MODULE__{
            closePrice: float(),
            cmd: Operation.t(),
            openPrice: float(),
            symbol: String.t(),
            volume: float()
          }

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

  @moduledoc """
  Query result for profit calculation.

  ## Parameters
  - `profit` profit in account currency.

  ## Handled Api methods
  - `getProfitCalculation`
  """

  @type t :: %__MODULE__{
          profit: float()
        }

  @enforce_keys [:profit]

  @derive Jason.Encoder
  defstruct profit: 0.0

  def new(%{"profit" => profit}) when is_number(profit) do
    %__MODULE__{
      profit: profit
    }
  end

  def match(method, data) when method in ["getProfitCalculation"] do
    {:ok, __MODULE__.new(data)}
  end

  def match(_method, _data) do
    {:no_match}
  end
end
