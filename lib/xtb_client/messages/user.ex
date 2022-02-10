defmodule XtbClient.Messages.UserInfo do
  @enforce_keys [:company_unit, :currency, :group, :ib_account, :leverage_mult, :trailing_stop]

  @derive Jason.Encoder
  defstruct company_unit: 0,
            currency: "",
            group: "",
            ib_account: false,
            leverage_mult: nil,
            spread_type: nil,
            trailing_stop: false

  def new(%{"spreadType" => spread_type} = args) when is_binary(spread_type) do
    value = __MODULE__.new(Map.delete(args, "spreadType"))
    %{value | spread_type: spread_type}
  end

  def new(%{
        "companyUnit" => company_unit,
        "currency" => currency,
        "group" => group,
        "ibAccount" => ib_account,
        "leverageMultiplier" => leverage_mult,
        "trailingStop" => trailing_stop
      })
      when is_number(company_unit) and is_binary(currency) and
             is_binary(group) and is_boolean(ib_account) and
             is_number(leverage_mult) and is_boolean(trailing_stop) do
    %__MODULE__{
      company_unit: company_unit,
      currency: currency,
      group: group,
      ib_account: ib_account,
      leverage_mult: leverage_mult / 100,
      trailing_stop: trailing_stop
    }
  end
end
