defmodule XtbClient.StreamingMessage do
  @moduledoc """
  Helper module for encoding and decoding streaming messages.
  """

  @type t :: %__MODULE__{
          method: String.t(),
          response_method: String.t(),
          params: map() | nil
        }
  @type token :: {:method, String.t()} | {:hashed_params, String.t(), String.t()}

  @enforce_keys [:method, :response_method, :params]
  defstruct method: "",
            response_method: "",
            params: nil

  def new(method, response_method, params \\ nil) do
    %__MODULE__{
      method: method,
      response_method: response_method,
      params: params
    }
  end

  def encode_token(%__MODULE__{method: "getTrades" = method_name}) do
    {:method, method_name}
  end

  def encode_token(%__MODULE__{method: method_name, params: %{symbol: symbol}}) do
    {:hashed_params, method_name, symbol}
  end

  def encode_token(%__MODULE__{method: method_name}) do
    {:method, method_name}
  end

  def decode_method_name({:method, method}) do
    method
  end

  def decode_method_name({:hashed_params, method, _symbol}) do
    method
  end
end
