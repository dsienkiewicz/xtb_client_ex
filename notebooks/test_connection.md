#!/usr/bin/env elixir

# Load dependencies
Mix.install([
  {:websockex, "~> 0.4"},
  {:jason, "~> 1.4"},
  {:dotenvy, "~> 0.8"}
])

# Load .env file
Dotenvy.source([".env", System.get_env()])

username = System.get_env("XTB_API_USERNAME")
password = System.get_env("XTB_API_PASSWORD")
url = System.get_env("XTB_API_URL")

IO.puts("Testing connection...")
IO.puts("Username: #{username}")
IO.puts("URL: #{url}")

params = [
  app_name: "XtbClient",
  type: :demo,
  url: url,
  user: username,
  password: password
]

# This should work now without crashing
case XtbClient.MainSocket.start_link(params) do
  {:ok, pid} ->
    IO.puts("✓ MainSocket started successfully: #{inspect(pid)}")
    
    # Wait a bit for login
    Process.sleep(2000)
    
    # Try to get stream session ID
    case XtbClient.MainSocket.stream_session_id(pid) do
      {:ok, session_id} ->
        IO.puts("✓ Stream session ID obtained: #{session_id}")
      {:error, reason} ->
        IO.puts("✗ Failed to get stream session ID: #{inspect(reason)}")
    end
    
    # Check if process is still alive
    if Process.alive?(pid) do
      IO.puts("✓ MainSocket process is still alive")
    else
      IO.puts("✗ MainSocket process died")
    end
    
  {:error, reason} ->
    IO.puts("✗ Failed to start MainSocket: #{inspect(reason)}")
end
