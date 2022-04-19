# XtbClient

[![Elixir CI](https://github.com/dsienkiewicz/xtb_client_ex/actions/workflows/elixir.yml/badge.svg?branch=main)](https://github.com/dsienkiewicz/xtb_client_ex/actions/workflows/elixir.yml)

Elixir client for the XTB trading platform.

Library provides simple client written as `GenServer` intended to be started as a process to communicate with XTB server.

As all regular OTP processes, the process for `XtbClient.Connection` could be supervised, registered locally or in distributed environment, monitored, traced, linked to other processes etc.

## Installation

Package could be added as a link to GitHub repo:

```elixir
def deps do
  [
    {:xtb_client_ex, github: "https://github.com/dsienkiewicz/xtb_client_ex"}    
  ]
end
```

When [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `xtb_client_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:xtb_client_ex, "~> 0.1.0"}
  ]
end
```

## Usage
Find more examples in the folder `examples/`.

### Starting client connection
```elixir
params = %{app_name: "XtbClient", type: :demo, url: "wss://ws.xtb.com", user: "<<USER_ID>>", password: "<<PASSWORD>>"}

{:ok, pid} = XtbClient.Connection.start_link(params)
```

### Subscribe to tick prices
```elixir
Code.require_file("./examples/stream_listener.ex")

{:ok, lpid} = StreamListener.start_link(%{})
params = %{app_name: "XtbClient", type: :demo, url: "wss://ws.xtb.com", user: "<<USER_ID>>", password: "<<PASSWORD>>"}
{:ok, cpid} = XtbClient.Connection.start_link(params)

args = %{symbol: "LITECOIN"}
query = XtbClient.Messages.Quotations.Query.new(args)
XtbClient.Connection.subscribe_get_tick_prices(cpid, lpid, query)

Listener handle info: {:ok,
 %XtbClient.Messages.TickPrice{
   ask: 131.45,
   ask_volume: 250,
   bid: 130.46,
   bid_volume: 250,
   exe_mode: nil,
   high: 132.38,
   level: 3,
   low: 127.94,
   quote_id: :five,
   spread_raw: 0.99,
   spread_table: 0.99,
   symbol: "LITECOIN",
   timestamp: ~U[2022-03-28 21:31:21.126Z]
 }}
Listener handle info: {:ok,
 %XtbClient.Messages.TickPrice{
   ask: 131.54,
   ask_volume: 500,
   bid: 130.39,
   bid_volume: 500,
   exe_mode: nil,
   high: 132.38,
   level: 4,
   low: 127.94,
   quote_id: :five,
   spread_raw: 1.15,
   spread_table: 1.15,
   symbol: "LITECOIN",
   timestamp: ~U[2022-03-28 21:31:21.126Z]
 }}
 ...
```

### Subscribe to candles
```elixir
Code.require_file("./examples/stream_listener.ex")

{ok, lpid} = StreamListener.start_link(%{})

params = %{app_name: "XtbClient", type: :demo, url: "wss://ws.xtb.com", user: "<<USER_ID>>", password: "<<PASSWORD>>"}
{:ok, cpid} = XtbClient.Connection.start_link(params)

args = "LITECOIN"
query = XtbClient.Messages.Candles.Query.new(args)
XtbClient.Connection.subscribe_get_candles(cpid, lpid, query)

Listener handle info: {:ok,
 %XtbClient.Messages.Candle{
   close: 130.69,
   ctm: ~U[2022-03-28 21:29:00.000Z],
   ctm_string: "Mar 28, 2022, 11:29:00 PM",
   high: 130.7,
   low: 130.63,
   open: 130.64,
   quote_id: :five,
   symbol: "LITECOIN",
   vol: 257.0
 }}
Listener handle info: {:ok,
 %XtbClient.Messages.Candle{
   close: 130.65,
   ctm: ~U[2022-03-28 21:30:00.000Z],
   ctm_string: "Mar 28, 2022, 11:30:00 PM",
   high: 130.7,
   low: 130.64,
   open: 130.68,
   quote_id: :five,
   symbol: "LITECOIN",
   vol: 216.0
 }}
 ...
```

## TODO
* Publish to HexPM