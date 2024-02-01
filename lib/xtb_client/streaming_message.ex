defmodule XtbClient.StreamingMessage do
  @moduledoc """
  Helper module for encoding and decoding streaming messages.
  """

  @type t :: %__MODULE__{
          method: String.t(),
          response_method: String.t(),
          metadata: map(),
          params: map() | nil
        }

  @type token :: {:method, String.t(), map()} | {:hashed_params, String.t(), String.t(), map()}

  @enforce_keys [:method, :response_method, :params]
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

  def encode_token(%__MODULE__{method: "getTrades" = method_name, metadata: metadata}) do
    {:method, method_name, metadata}
  end

  def encode_token(%__MODULE__{method: method_name, params: %{symbol: symbol}, metadata: metadata}) do
    {:hashed_params, method_name, symbol, metadata}
  end

  def encode_token(%__MODULE__{method: method_name, metadata: metadata}) do
    {:method, method_name, metadata}
  end

  def decode_method_name({:method, method, _metadata}) do
    method
  end

  def decode_method_name({:hashed_params, method, _symbol, _metadata}) do
    method
  end

  def decode_metadata({:method, _method, metadata}) do
    metadata
  end

  def decode_metadata({:hashed_params, _method, _symbol, metadata}) do
    metadata
  end
end
