defmodule XtbClient.Messages.UserInfo do
  @moduledoc """
  Info about the current user.

  ## Parameters
  - `company_unit` unit the account is assigned to,
  - `currency` account currency,
  - `group` group name,
  - `ib_account` indicates whether this account is an IB account,
  - `leverage_mult` the factor used for margin calculations,
  - `spread_type` spread type, `null` if not applicable,
  - `trailing_stop` indicates whether this account is enabled to use trailing stop.

  ## Handled Api methods
  - `getCurrentUserData`
  """

  @type t :: %__MODULE__{
          company_unit: integer(),
          currency: String.t(),
          group: String.t(),
          ib_account: true | false,
          leverage_mult: float(),
          spread_type: String.t() | nil,
          trailing_stop: boolean()
        }

  @enforce_keys [
    :company_unit,
    :currency,
    :group,
    :ib_account,
    :leverage_mult,
    :spread_type,
    :trailing_stop
  ]
  @derive Jason.Encoder
  defstruct company_unit: 0,
            currency: "",
            group: "",
            ib_account: false,
            leverage_mult: nil,
            spread_type: nil,
            trailing_stop: false

  def new(%{"spreadType" => spread_type} = args) do
    value = args |> Map.drop(["spreadType"]) |> new()

    %{value | spread_type: spread_type || ""}
  end

  def new(%{
        "companyUnit" => company_unit,
        "currency" => currency,
        "group" => group,
        "ibAccount" => ib_account,
        "leverageMultiplier" => leverage_mult,
        "trailingStop" => trailing_stop
      })
      when is_number(company_unit) and
             is_boolean(ib_account) and
             is_number(leverage_mult) do
    %__MODULE__{
      company_unit: company_unit,
      currency: currency || "",
      group: group || "",
      ib_account: ib_account,
      spread_type: nil,
      leverage_mult: leverage_mult / 100,
      trailing_stop: trailing_stop || ""
    }
  end
end
