defmodule XtbClient.StreamingMessage do
  @moduledoc """
  Module for handling streaming messages with XTB Api.

  This module provides functions for parsing messages from the XTB API.
  """

  @doc "Returns a string representation of the subscribe operation."
  @callback operation(struct :: struct()) :: String.t()

  @doc "Returns a JSON path to get the response object."
  @callback response_path(struct :: struct()) :: String.t()

  @doc "Encodes the message."
  @callback encode(struct :: struct()) :: map()

  @doc "Decodes the message."
  @callback decode(data :: term()) :: struct()

  @doc "Calculates a unique hash for the message, which must be the same for related subscribe and unsubscribe messages."
  @callback hash(struct :: struct()) :: String.t()

  @callback fetch_metadata(struct :: struct()) :: map() | nil

  @type t :: %__MODULE__{
          method: String.t(),
          response_method: String.t(),
          metadata: map(),
          params: map() | nil
        }

  @enforce_keys [:method, :response_method, :metadata, :params]
  defstruct method: "",
            response_method: "",
            metadata: %{},
            params: nil

  def new(method, response_method, metadata, params \\ nil) do
    %__MODULE__{
      method: method,
      response_method: response_method,
      metadata: metadata,
      params: params
    }
  end

  def get_method_name(%__MODULE__{method: method_name}) do
    method_name
  end

  def get_metadata(%__MODULE__{metadata: metadata}) do
    metadata
  end
end
