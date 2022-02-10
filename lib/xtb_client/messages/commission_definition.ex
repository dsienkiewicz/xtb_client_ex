defmodule XtbClient.Messages.CommissionDefinition do
  defmodule Result do
    @enforce_keys [:commission, :rate_of_exchange]

    @derive Jason.Encoder
    defstruct commission: 0.0,
              rate_of_exchange: 0.0

    def new(%{"commission" => commission, "rateOfExchange" => rate_of_exchange})
        when is_number(commission) and is_number(rate_of_exchange) do
      %__MODULE__{
        commission: commission,
        rate_of_exchange: rate_of_exchange
      }
    end
  end
end
