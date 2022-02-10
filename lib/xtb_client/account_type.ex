defmodule XtbClient.AccountType do
  def format_main(account_type) when is_atom(account_type) do
    case account_type do
      :demo -> "demo"
      :real -> "real"
    end
  end

  def format_streaming(account_type) when is_atom(account_type) do
    case account_type do
      :demo -> "demoStream"
      :real -> "realStream"
    end
  end
end
