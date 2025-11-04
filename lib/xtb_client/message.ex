defmodule XtbClient.Message do
  @moduledoc """
  Module for handling synchronous messages with XTB Api.

  This module provides functions for parsing messages from the XTB API.
  """

  @doc "Returns a string representation of the operation."
  @callback operation(struct :: struct()) :: String.t()

  @doc "Encodes the message."
  @callback encode(struct :: struct()) :: map()

  @doc "Decodes the message."
  @callback decode(data :: term()) :: struct()
end
