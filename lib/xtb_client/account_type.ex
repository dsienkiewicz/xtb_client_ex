defmodule XtbClient.AccountType do
  @moduledoc """
  Atoms representing type of account.
  """

  @type t :: :demo | :real

  @doc """
  Format an atom representing main type of the account to string.
  """
  @spec format_main(t()) :: binary()
  def format_main(account_type) when is_atom(account_type) do
    case account_type do
      :demo -> "demo"
      :real -> "real"
    end
  end

  @doc """
  Format and atom representing streaming type of the account to string.
  """
  @spec format_streaming(t()) :: binary()
  def format_streaming(account_type) when is_atom(account_type) do
    case account_type do
      :demo -> "demoStream"
      :real -> "realStream"
    end
  end
end
