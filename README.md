# XtbClient

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `xtb_client_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:xtb_client_ex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/xtb_client_ex](https://hexdocs.pm/xtb_client_ex).

## Manual testing
```elixir
params = %{app_name: "XtbClient", password: "<<PASSWORD>>", type: :demo, url: "wss://ws.xtb.com", user: "<<USER_ID>>"}

{:ok, pid} = XtbClient.Connection.start_link(params)

symb = XtbClient.Connection.get_all_symbols(pid)
```