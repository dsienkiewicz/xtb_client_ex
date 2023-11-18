defmodule XtbClient.AccountType do
  @moduledoc """
  Helper module for handling with type of account.
  """

  @type t :: :demo | :real

  @doc """
  Format an atom representing main type of the account to string.
  """
  @spec format_main(t()) :: String.t()
  def format_main(:demo), do: "demo"
  def format_main(:real), do: "real"
  def format_main(other), do: raise("Unknown account type: #{inspect(other)}")

  @doc """
  Format and atom representing streaming type of the account to string.
  """
  @spec format_streaming(t()) :: String.t()
  def format_streaming(:demo), do: "demoStream"
  def format_streaming(:real), do: "realStream"
  def format_streaming(other), do: raise("Unknown account type: #{inspect(other)}")
end
